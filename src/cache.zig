const std = @import("std");
const contribution_languages = @import("contribution_languages.zig");

pub const ContributionLanguage = contribution_languages.LanguageContribution;

const cache_version = 6;

const CacheEntry = struct {
    key: []const u8,
    pushed_at: []const u8,
    lines_changed: ?u32 = null,
    views: ?u32 = null,
    contribution_languages: ?[]ContributionLanguage = null,

    fn deinit(self: CacheEntry, allocator: std.mem.Allocator) void {
        allocator.free(self.key);
        allocator.free(self.pushed_at);
        if (self.contribution_languages) |languages| {
            for (languages) |language| language.deinit(allocator);
            allocator.free(languages);
        }
    }
};

const JsonCache = struct {
    version: u32 = cache_version,
    entries: []JsonEntry = &.{},
};

const JsonEntry = struct {
    key: []const u8,
    pushed_at: []const u8,
    lines_changed: ?u32 = null,
    views: ?u32 = null,
    contribution_languages: ?[]ContributionLanguage = null,
};

allocator: std.mem.Allocator,
path: ?[]const u8,
entries: std.ArrayList(CacheEntry) = .empty,
dirty: bool = false,

const Self = @This();

pub fn init(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: ?[]const u8,
) !Self {
    var self: Self = .{
        .allocator = allocator,
        .path = path,
    };
    errdefer self.deinit();
    if (path) |p| {
        try self.load(io, p);
    }
    return self;
}

pub fn deinit(self: *Self) void {
    for (self.entries.items) |entry| {
        entry.deinit(self.allocator);
    }
    self.entries.deinit(self.allocator);
}

pub fn keyForRepo(repo_id: []const u8, fallback_name: []const u8) [64]u8 {
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    const stable = if (repo_id.len > 0) repo_id else fallback_name;
    std.crypto.hash.sha2.Sha256.hash(stable, &digest, .{});
    return std.fmt.bytesToHex(digest, .lower);
}

pub fn getLinesChanged(
    self: *Self,
    key: []const u8,
    pushed_at: []const u8,
) ?u32 {
    const entry = self.findCurrent(key, pushed_at) orelse return null;
    return entry.lines_changed;
}

pub fn getViews(
    self: *Self,
    key: []const u8,
    pushed_at: []const u8,
) ?u32 {
    const entry = self.findCurrent(key, pushed_at) orelse return null;
    return entry.views;
}

pub fn getContributionLanguages(
    self: *Self,
    key: []const u8,
    pushed_at: []const u8,
) ?[]const ContributionLanguage {
    const entry = self.findCurrent(key, pushed_at) orelse return null;
    return entry.contribution_languages;
}

pub fn putLinesChanged(
    self: *Self,
    key: []const u8,
    pushed_at: []const u8,
    lines_changed: u32,
) !void {
    const entry = try self.getOrPut(key, pushed_at);
    if (entry.lines_changed != lines_changed) {
        entry.lines_changed = lines_changed;
        self.dirty = true;
    }
}

pub fn putViews(
    self: *Self,
    key: []const u8,
    pushed_at: []const u8,
    views: u32,
) !void {
    const entry = try self.getOrPut(key, pushed_at);
    if (entry.views != views) {
        entry.views = views;
        self.dirty = true;
    }
}

pub fn putContributionLanguages(
    self: *Self,
    key: []const u8,
    pushed_at: []const u8,
    contribution_languages_: []const ContributionLanguage,
) !void {
    const entry = try self.getOrPut(key, pushed_at);
    if (entry.contribution_languages) |languages| {
        for (languages) |language| language.deinit(self.allocator);
        self.allocator.free(languages);
        entry.contribution_languages = null;
    }
    entry.contribution_languages = try contribution_languages.dupeAll(
        self.allocator,
        contribution_languages_,
    );
    self.dirty = true;
}

pub fn save(self: *Self, io: std.Io) !void {
    const path = self.path orelse return;
    if (!self.dirty) return;

    var arena = std.heap.ArenaAllocator.init(self.allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const json_entries = try a.alloc(JsonEntry, self.entries.items.len);
    for (self.entries.items, json_entries) |entry, *json_entry| {
        json_entry.* = .{
            .key = entry.key,
            .pushed_at = entry.pushed_at,
            .lines_changed = entry.lines_changed,
            .views = entry.views,
            .contribution_languages = entry.contribution_languages,
        };
    }

    const rendered = try std.json.Stringify.valueAlloc(
        a,
        JsonCache{ .version = cache_version, .entries = json_entries },
        .{ .whitespace = .indent_2 },
    );
    try writeFile(io, path, rendered);
    self.dirty = false;
    std.log.info("Saved repository stats cache to '{s}'", .{path});
}

fn load(self: *Self, io: std.Io, path: []const u8) !void {
    var file = std.Io.Dir.cwd().openFile(io, path, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            std.log.info("No repository stats cache found at '{s}'", .{path});
            return;
        },
        else => return err,
    };
    defer file.close(io);

    var arena = std.heap.ArenaAllocator.init(self.allocator);
    defer arena.deinit();
    var read_buffer: [64 * 1024]u8 = undefined;
    var reader = file.reader(io, &read_buffer);
    const data = try (&reader.interface).allocRemaining(arena.allocator(), .unlimited);
    const parsed = std.json.parseFromSliceLeaky(
        JsonCache,
        arena.allocator(),
        data,
        .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
    ) catch |err| {
        std.log.warn("Ignoring unreadable repository stats cache: {s}", .{@errorName(err)});
        return;
    };

    const load_contribution_languages = parsed.version == cache_version;
    try self.entries.ensureTotalCapacity(self.allocator, parsed.entries.len);
    for (parsed.entries) |entry| {
        if (entry.key.len == 0 or entry.pushed_at.len == 0) continue;
        self.entries.appendAssumeCapacity(.{
            .key = try self.allocator.dupe(u8, entry.key),
            .pushed_at = try self.allocator.dupe(u8, entry.pushed_at),
            .lines_changed = entry.lines_changed,
            .views = entry.views,
            .contribution_languages = if (load_contribution_languages)
                if (entry.contribution_languages) |languages|
                    try contribution_languages.dupeAll(self.allocator, languages)
                else
                    null
            else
                null,
        });
    }
    std.log.info(
        "Loaded repository stats cache with {d} entr{s}",
        .{ self.entries.items.len, if (self.entries.items.len == 1) "y" else "ies" },
    );
}

fn findCurrent(
    self: *Self,
    key: []const u8,
    pushed_at: []const u8,
) ?*CacheEntry {
    const entry = self.findByKey(key) orelse return null;
    if (!std.mem.eql(u8, entry.pushed_at, pushed_at)) return null;
    return entry;
}

fn findByKey(self: *Self, key: []const u8) ?*CacheEntry {
    for (self.entries.items) |*entry| {
        if (std.mem.eql(u8, entry.key, key)) return entry;
    }
    return null;
}

fn getOrPut(
    self: *Self,
    key: []const u8,
    pushed_at: []const u8,
) !*CacheEntry {
    if (self.findByKey(key)) |entry| {
        if (!std.mem.eql(u8, entry.pushed_at, pushed_at)) {
            const new_pushed_at = try self.allocator.dupe(u8, pushed_at);
            self.allocator.free(entry.pushed_at);
            entry.pushed_at = new_pushed_at;
            entry.lines_changed = null;
            entry.views = null;
            if (entry.contribution_languages) |languages| {
                for (languages) |language| language.deinit(self.allocator);
                self.allocator.free(languages);
                entry.contribution_languages = null;
            }
            self.dirty = true;
        }
        return entry;
    }

    try self.entries.append(self.allocator, .{
        .key = try self.allocator.dupe(u8, key),
        .pushed_at = try self.allocator.dupe(u8, pushed_at),
    });
    self.dirty = true;
    return &self.entries.items[self.entries.items.len - 1];
}

fn writeFile(io: std.Io, path: []const u8, data: []const u8) !void {
    if (std.fs.path.dirname(path)) |parent| {
        if (parent.len > 0) {
            try std.Io.Dir.cwd().createDirPath(io, parent);
        }
    }
    const out = try std.Io.Dir.cwd().createFile(io, path, .{});
    defer out.close(io);
    var write_buffer: [64 * 1024]u8 = undefined;
    var writer = out.writer(io, &write_buffer);
    try writer.interface.writeAll(data);
    try writer.interface.flush();
}

test "v1 cache loads without contribution languages" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const path = try std.fmt.allocPrint(
        std.testing.allocator,
        ".zig-cache/tmp/{s}/repo_stats_cache.json",
        .{tmp.sub_path},
    );
    defer std.testing.allocator.free(path);
    try writeFile(std.testing.io, path,
        \\{
        \\  "version": 1,
        \\  "entries": [
        \\    {
        \\      "key": "repo-key",
        \\      "pushed_at": "2026-01-01T00:00:00Z",
        \\      "lines_changed": 42,
        \\      "views": 7
        \\    }
        \\  ]
        \\}
    );

    var cache = try Self.init(std.testing.allocator, std.testing.io, path);
    defer cache.deinit();
    try std.testing.expectEqual(
        @as(?u32, 42),
        cache.getLinesChanged("repo-key", "2026-01-01T00:00:00Z"),
    );
    try std.testing.expectEqual(
        @as(?u32, 7),
        cache.getViews("repo-key", "2026-01-01T00:00:00Z"),
    );
    try std.testing.expect(cache.getContributionLanguages(
        "repo-key",
        "2026-01-01T00:00:00Z",
    ) == null);
}

test "v5 contribution languages are ignored after generated-path cache bump" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const path = try std.fmt.allocPrint(
        std.testing.allocator,
        ".zig-cache/tmp/{s}/repo_stats_cache.json",
        .{tmp.sub_path},
    );
    defer std.testing.allocator.free(path);
    try writeFile(std.testing.io, path,
        \\{
        \\  "version": 5,
        \\  "entries": [
        \\    {
        \\      "key": "repo-key",
        \\      "pushed_at": "2026-01-01T00:00:00Z",
        \\      "lines_changed": 42,
        \\      "views": 7,
        \\      "contribution_languages": [
        \\        { "name": "Other", "color": "#ededed", "lines_changed": 42 }
        \\      ]
        \\    }
        \\  ]
        \\}
    );

    var cache = try Self.init(std.testing.allocator, std.testing.io, path);
    defer cache.deinit();
    try std.testing.expectEqual(
        @as(?u32, 42),
        cache.getLinesChanged("repo-key", "2026-01-01T00:00:00Z"),
    );
    try std.testing.expect(cache.getContributionLanguages(
        "repo-key",
        "2026-01-01T00:00:00Z",
    ) == null);
}

test "v6 contribution languages round-trip and invalidate on pushedAt change" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const path = try std.fmt.allocPrint(
        std.testing.allocator,
        ".zig-cache/tmp/{s}/repo_stats_cache.json",
        .{tmp.sub_path},
    );
    defer std.testing.allocator.free(path);

    const languages = [_]ContributionLanguage{
        .{ .name = "Zig", .color = "#ec915c", .lines_changed = 12 },
        .{ .name = "C", .color = "#555555", .lines_changed = 3 },
    };

    {
        var cache = try Self.init(std.testing.allocator, std.testing.io, path);
        defer cache.deinit();
        try cache.putLinesChanged("repo-key", "2026-01-01T00:00:00Z", 15);
        try cache.putContributionLanguages(
            "repo-key",
            "2026-01-01T00:00:00Z",
            &languages,
        );
        try cache.save(std.testing.io);
    }

    {
        var cache = try Self.init(std.testing.allocator, std.testing.io, path);
        defer cache.deinit();
        const cached = cache.getContributionLanguages(
            "repo-key",
            "2026-01-01T00:00:00Z",
        ).?;
        try std.testing.expectEqual(@as(usize, 2), cached.len);
        try std.testing.expectEqualStrings("Zig", cached[0].name);
        try std.testing.expectEqual(@as(u32, 12), cached[0].lines_changed);

        try cache.putLinesChanged("repo-key", "2026-02-01T00:00:00Z", 1);
        try std.testing.expect(cache.getContributionLanguages(
            "repo-key",
            "2026-02-01T00:00:00Z",
        ) == null);
    }
}
