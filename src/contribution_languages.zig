const std = @import("std");

pub const LanguageContribution = struct {
    name: []const u8,
    color: ?[]const u8 = null,
    lines_changed: u32,

    pub fn deinit(self: @This(), allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        if (self.color) |color| allocator.free(color);
    }
};

const Classification = struct {
    name: []const u8,
    color: ?[]const u8 = null,
};

const Rule = struct {
    pattern: []const u8,
    name: []const u8,
    color: ?[]const u8 = null,
};

// A compact, pinned subset of GitHub Linguist rules. Exact filename rules are
// checked before extension rules, matching Linguist precedence for these cases.
const exact_filename_rules = [_]Rule{
    .{ .pattern = "Makefile", .name = "Makefile", .color = "#427819" },
    .{ .pattern = "BSDmakefile", .name = "Makefile", .color = "#427819" },
    .{ .pattern = "GNUmakefile", .name = "Makefile", .color = "#427819" },
    .{ .pattern = "CMakeLists.txt", .name = "CMake", .color = "#da3434" },
    .{ .pattern = "Dockerfile", .name = "Dockerfile", .color = "#384d54" },
    .{ .pattern = "Gemfile", .name = "Ruby", .color = "#701516" },
    .{ .pattern = "Rakefile", .name = "Ruby", .color = "#701516" },
    .{ .pattern = "go.mod", .name = "Go", .color = "#00add8" },
    .{ .pattern = "go.sum", .name = "Go", .color = "#00add8" },
    .{ .pattern = "meson.build", .name = "Meson", .color = "#007800" },
    .{ .pattern = "meson_options.txt", .name = "Meson", .color = "#007800" },
    .{ .pattern = "Justfile", .name = "Just", .color = "#384d54" },
    .{ .pattern = "justfile", .name = "Just", .color = "#384d54" },
};

const extension_rules = [_]Rule{
    .{ .pattern = ".c", .name = "C", .color = "#555555" },
    .{ .pattern = ".h", .name = "C", .color = "#555555" },
    .{ .pattern = ".s", .name = "Assembly", .color = "#6e4c13" },
    .{ .pattern = ".asm", .name = "Assembly", .color = "#6e4c13" },
    .{ .pattern = ".inc", .name = "Assembly", .color = "#6e4c13" },
    .{ .pattern = ".m", .name = "Objective-C", .color = "#438eff" },
    .{ .pattern = ".mm", .name = "Objective-C++", .color = "#6866fb" },
    .{ .pattern = ".cc", .name = "C++", .color = "#f34b7d" },
    .{ .pattern = ".cpp", .name = "C++", .color = "#f34b7d" },
    .{ .pattern = ".cxx", .name = "C++", .color = "#f34b7d" },
    .{ .pattern = ".hpp", .name = "C++", .color = "#f34b7d" },
    .{ .pattern = ".hh", .name = "C++", .color = "#f34b7d" },
    .{ .pattern = ".zig", .name = "Zig", .color = "#ec915c" },
    .{ .pattern = ".rs", .name = "Rust", .color = "#dea584" },
    .{ .pattern = ".go", .name = "Go", .color = "#00add8" },
    .{ .pattern = ".py", .name = "Python", .color = "#3572a5" },
    .{ .pattern = ".js", .name = "JavaScript", .color = "#f1e05a" },
    .{ .pattern = ".jsx", .name = "JavaScript", .color = "#f1e05a" },
    .{ .pattern = ".ts", .name = "TypeScript", .color = "#3178c6" },
    .{ .pattern = ".tsx", .name = "TypeScript", .color = "#3178c6" },
    .{ .pattern = ".java", .name = "Java", .color = "#b07219" },
    .{ .pattern = ".kt", .name = "Kotlin", .color = "#a97bff" },
    .{ .pattern = ".kts", .name = "Kotlin", .color = "#a97bff" },
    .{ .pattern = ".swift", .name = "Swift", .color = "#f05138" },
    .{ .pattern = ".rb", .name = "Ruby", .color = "#701516" },
    .{ .pattern = ".php", .name = "PHP", .color = "#4f5d95" },
    .{ .pattern = ".pl", .name = "Perl", .color = "#0298c3" },
    .{ .pattern = ".pm", .name = "Perl", .color = "#0298c3" },
    .{ .pattern = ".cs", .name = "C#", .color = "#178600" },
    .{ .pattern = ".fs", .name = "F#", .color = "#b845fc" },
    .{ .pattern = ".html", .name = "HTML", .color = "#e34c26" },
    .{ .pattern = ".htm", .name = "HTML", .color = "#e34c26" },
    .{ .pattern = ".css", .name = "CSS", .color = "#563d7c" },
    .{ .pattern = ".scss", .name = "SCSS", .color = "#c6538c" },
    .{ .pattern = ".sass", .name = "Sass", .color = "#a53b70" },
    .{ .pattern = ".sh", .name = "Shell", .color = "#89e051" },
    .{ .pattern = ".bash", .name = "Shell", .color = "#89e051" },
    .{ .pattern = ".zsh", .name = "Shell", .color = "#89e051" },
    .{ .pattern = ".fish", .name = "Shell", .color = "#89e051" },
    .{ .pattern = ".ps1", .name = "PowerShell", .color = "#012456" },
    .{ .pattern = ".bat", .name = "Batchfile", .color = "#c1f12e" },
    .{ .pattern = ".cmd", .name = "Batchfile", .color = "#c1f12e" },
    .{ .pattern = ".sql", .name = "SQL", .color = "#e38c00" },
    .{ .pattern = ".lua", .name = "Lua", .color = "#000080" },
    .{ .pattern = ".vim", .name = "Vim Script", .color = "#199f4b" },
    .{ .pattern = ".nix", .name = "Nix", .color = "#7e7eff" },
    .{ .pattern = ".dart", .name = "Dart", .color = "#00b4ab" },
    .{ .pattern = ".ex", .name = "Elixir", .color = "#6e4a7e" },
    .{ .pattern = ".exs", .name = "Elixir", .color = "#6e4a7e" },
    .{ .pattern = ".erl", .name = "Erlang", .color = "#b83998" },
    .{ .pattern = ".hrl", .name = "Erlang", .color = "#b83998" },
    .{ .pattern = ".r", .name = "R", .color = "#198ce7" },
    .{ .pattern = ".tf", .name = "HCL", .color = "#844fba" },
    .{ .pattern = ".hcl", .name = "HCL", .color = "#844fba" },
    .{ .pattern = ".vue", .name = "Vue", .color = "#41b883" },
    .{ .pattern = ".asl", .name = "ASL", .color = null },
    .{ .pattern = ".dsl", .name = "ASL", .color = null },
    .{ .pattern = ".ld", .name = "Linker Script", .color = null },
    .{ .pattern = ".lds", .name = "Linker Script", .color = null },
    .{ .pattern = ".y", .name = "Yacc", .color = "#4b6c4b" },
    .{ .pattern = ".yacc", .name = "Yacc", .color = "#4b6c4b" },
    .{ .pattern = ".l", .name = "Lex", .color = "#dbca00" },
    .{ .pattern = ".lex", .name = "Lex", .color = "#dbca00" },
    .{ .pattern = ".m4", .name = "M4", .color = null },
    .{ .pattern = ".awk", .name = "Awk", .color = "#c30e9b" },
    .{ .pattern = ".roff", .name = "Roff", .color = "#ecdebe" },
    .{ .pattern = ".1", .name = "Roff", .color = "#ecdebe" },
    .{ .pattern = ".2", .name = "Roff", .color = "#ecdebe" },
    .{ .pattern = ".3", .name = "Roff", .color = "#ecdebe" },
    .{ .pattern = ".5", .name = "Roff", .color = "#ecdebe" },
    .{ .pattern = ".7", .name = "Roff", .color = "#ecdebe" },
    .{ .pattern = ".8", .name = "Roff", .color = "#ecdebe" },
    .{ .pattern = ".pas", .name = "Pascal", .color = "#e3f171" },
    .{ .pattern = ".p", .name = "Pascal", .color = "#e3f171" },
    .{ .pattern = ".uc", .name = "UnrealScript", .color = "#a54c4d" },
    .{ .pattern = ".gsc", .name = "GSC", .color = null },
    .{ .pattern = ".csc", .name = "GSC", .color = null },
    .{ .pattern = ".cocci", .name = "SmPL", .color = "#c94949" },
    .{ .pattern = ".nasl", .name = "NASL", .color = null },
    .{ .pattern = ".xm", .name = "Logos", .color = null },
    .{ .pattern = ".x", .name = "Logos", .color = null },
    .{ .pattern = ".hlsl", .name = "HLSL", .color = "#aace60" },
    .{ .pattern = ".fx", .name = "HLSL", .color = "#aace60" },
    .{ .pattern = ".jinja", .name = "Jinja", .color = "#a52a22" },
    .{ .pattern = ".jinja2", .name = "Jinja", .color = "#a52a22" },
    .{ .pattern = ".j2", .name = "Jinja", .color = "#a52a22" },
    .{ .pattern = ".feature", .name = "Gherkin", .color = "#5b2063" },
    .{ .pattern = ".xpl", .name = "XProc", .color = null },
    .{ .pattern = ".xproc", .name = "XProc", .color = null },
    .{ .pattern = ".bb", .name = "BitBake", .color = null },
    .{ .pattern = ".bbappend", .name = "BitBake", .color = null },
    .{ .pattern = ".bbclass", .name = "BitBake", .color = null },
    .{ .pattern = ".nsi", .name = "NSIS", .color = null },
    .{ .pattern = ".nsh", .name = "NSIS", .color = null },
    .{ .pattern = ".metal", .name = "Metal", .color = "#8f14e9" },
    .{ .pattern = ".tpl", .name = "Smarty", .color = null },
    .{ .pattern = ".gotmpl", .name = "Go Template", .color = null },
    .{ .pattern = ".tmpl", .name = "Go Template", .color = null },
    .{ .pattern = ".xsl", .name = "XSLT", .color = "#eb8ceb" },
    .{ .pattern = ".xslt", .name = "XSLT", .color = "#eb8ceb" },
    .{ .pattern = ".i", .name = "SWIG", .color = null },
    .{ .pattern = ".slim", .name = "Slim", .color = "#2b2b2b" },
    .{ .pattern = ".sed", .name = "sed", .color = "#64b970" },
    .{ .pattern = ".clj", .name = "Clojure", .color = "#db5855" },
    .{ .pattern = ".cljs", .name = "Clojure", .color = "#db5855" },
    .{ .pattern = ".cljc", .name = "Clojure", .color = "#db5855" },
    .{ .pattern = ".tex", .name = "TeX", .color = "#3d6117" },
    .{ .pattern = ".gdb", .name = "GDB", .color = null },
    .{ .pattern = ".xs", .name = "XS", .color = null },
    .{ .pattern = ".tcl", .name = "Tcl", .color = "#e4cc98" },
    .{ .pattern = ".raku", .name = "Raku", .color = "#0000fb" },
    .{ .pattern = ".rakumod", .name = "Raku", .color = "#0000fb" },
    .{ .pattern = ".pm6", .name = "Raku", .color = "#0000fb" },
    .{ .pattern = ".el", .name = "Emacs Lisp", .color = "#c065db" },
};

const ignored_path_components = [_][]const u8{
    ".build",
    ".dart_tool",
    ".gradle",
    ".swiftpm",
    "build",
    "Carthage",
    "DerivedData",
    "dist",
    "external",
    "Generated",
    "node_modules",
    "out",
    "Pods",
    "target",
    "third_party",
    "third-party",
    "vendor",
    "vendors",
};

pub fn classifyPath(path: []const u8) ?Classification {
    const clean = normalizePathForClassification(path);
    if (isIgnoredPath(clean)) return null;
    const basename = std.fs.path.basename(clean);
    for (exact_filename_rules) |rule| {
        if (std.ascii.eqlIgnoreCase(basename, rule.pattern)) {
            return .{ .name = rule.name, .color = rule.color };
        }
    }
    for (extension_rules) |rule| {
        if (basename.len > rule.pattern.len and
            std.ascii.endsWithIgnoreCase(basename, rule.pattern))
        {
            return .{ .name = rule.name, .color = rule.color };
        }
    }
    return null;
}

fn isIgnoredPath(path: []const u8) bool {
    var components = std.mem.splitScalar(u8, path, '/');
    while (components.next()) |component| {
        if (component.len == 0) continue;
        for (ignored_path_components) |ignored| {
            if (std.ascii.eqlIgnoreCase(component, ignored)) {
                return true;
            }
        }
    }
    return false;
}

pub fn parseNumstat(
    allocator: std.mem.Allocator,
    numstat: []const u8,
) ![]LanguageContribution {
    var tally = Tally.init(allocator);
    defer tally.deinit();

    var lines = std.mem.tokenizeScalar(u8, numstat, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, "\r");
        var fields = std.mem.splitScalar(u8, line, '\t');
        const additions_text = fields.next() orelse continue;
        const deletions_text = fields.next() orelse continue;
        const path = fields.rest();
        if (path.len == 0) continue;
        if (std.mem.eql(u8, additions_text, "-") or
            std.mem.eql(u8, deletions_text, "-"))
        {
            continue;
        }
        const additions = std.fmt.parseUnsigned(u32, additions_text, 10) catch continue;
        const deletions = std.fmt.parseUnsigned(u32, deletions_text, 10) catch continue;
        try tally.add(path, additions + deletions);
    }

    return try tally.toOwnedSlice();
}

fn parsePatch(
    allocator: std.mem.Allocator,
    patch: []const u8,
) ![]LanguageContribution {
    var tally = Tally.init(allocator);
    defer tally.deinit();

    var old_path: []const u8 = "";
    var new_path: []const u8 = "";
    var in_hunk = false;

    var lines = std.mem.splitScalar(u8, patch, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, "\r");
        if (std.mem.startsWith(u8, line, "diff --git ")) {
            old_path = "";
            new_path = "";
            in_hunk = false;
            continue;
        }
        if (in_hunk) {
            if (std.mem.startsWith(u8, line, "@@")) continue;
            if (line.len == 0) continue;
            if (std.mem.startsWith(u8, line, "\\ No newline")) continue;

            if (line[0] == '+') {
                if (!std.mem.eql(u8, new_path, "/dev/null")) {
                    try tally.add(new_path, 1);
                }
            } else if (line[0] == '-') {
                if (!std.mem.eql(u8, old_path, "/dev/null")) {
                    try tally.add(old_path, 1);
                }
            }
            continue;
        }
        if (std.mem.startsWith(u8, line, "--- ")) {
            old_path = parsePatchPath(line[4..]);
            in_hunk = false;
            continue;
        }
        if (std.mem.startsWith(u8, line, "+++ ")) {
            new_path = parsePatchPath(line[4..]);
            in_hunk = false;
            continue;
        }
        if (std.mem.startsWith(u8, line, "@@")) {
            in_hunk = true;
            continue;
        }
    }

    return try tally.toOwnedSlice();
}

fn parsePatchPath(raw: []const u8) []const u8 {
    var path = std.mem.trim(u8, raw, " \t");
    if (std.mem.indexOfAny(u8, path, "\t ")) |end| {
        path = path[0..end];
    }
    if (std.mem.eql(u8, path, "/dev/null")) return path;
    if (std.mem.startsWith(u8, path, "a/") or
        std.mem.startsWith(u8, path, "b/"))
    {
        return path[2..];
    }
    return path;
}

fn normalizePathForClassification(path: []const u8) []const u8 {
    var clean = std.mem.trim(u8, path, " \t");
    if (std.mem.indexOf(u8, clean, " => ")) |arrow| {
        clean = std.mem.trim(u8, clean[arrow + 4 ..], " \t");
        if (std.mem.indexOfScalar(u8, clean, '}')) |brace| {
            if (brace + 1 == clean.len) {
                clean = clean[0..brace];
            }
        }
    }
    if (clean.len >= 2 and clean[0] == '"' and clean[clean.len - 1] == '"') {
        clean = clean[1 .. clean.len - 1];
    }
    if (std.mem.startsWith(u8, clean, "a/") or
        std.mem.startsWith(u8, clean, "b/"))
    {
        clean = clean[2..];
    }
    return clean;
}

const Tally = struct {
    allocator: std.mem.Allocator,
    map: std.StringHashMap(TallyEntry),

    const TallyEntry = struct {
        color: ?[]const u8,
        lines_changed: u32,
    };

    fn init(allocator: std.mem.Allocator) Tally {
        return .{
            .allocator = allocator,
            .map = .init(allocator),
        };
    }

    fn deinit(self: *Tally) void {
        self.map.deinit();
    }

    fn add(self: *Tally, path: []const u8, lines_changed: u32) !void {
        if (lines_changed == 0 or path.len == 0) return;
        const language = classifyPath(path) orelse return;
        const entry = try self.map.getOrPut(language.name);
        if (!entry.found_existing) {
            entry.value_ptr.* = .{
                .color = language.color,
                .lines_changed = 0,
            };
        }
        entry.value_ptr.lines_changed += lines_changed;
    }

    fn toOwnedSlice(self: *Tally) ![]LanguageContribution {
        var result = try self.allocator.alloc(LanguageContribution, self.map.count());
        var initialized: usize = 0;
        errdefer {
            for (result[0..initialized]) |language| language.deinit(self.allocator);
            self.allocator.free(result);
        }

        var i: usize = 0;
        var iterator = self.map.iterator();
        while (iterator.next()) |entry| : (i += 1) {
            const name = try self.allocator.dupe(u8, entry.key_ptr.*);
            errdefer self.allocator.free(name);
            const color = if (entry.value_ptr.color) |color|
                try self.allocator.dupe(u8, color)
            else
                null;
            result[i] = .{
                .name = name,
                .color = color,
                .lines_changed = entry.value_ptr.lines_changed,
            };
            initialized += 1;
        }

        std.sort.pdq(LanguageContribution, result, {}, struct {
            pub fn lessThan(_: void, lhs: LanguageContribution, rhs: LanguageContribution) bool {
                if (lhs.lines_changed == rhs.lines_changed) {
                    return std.mem.lessThan(u8, lhs.name, rhs.name);
                }
                return lhs.lines_changed > rhs.lines_changed;
            }
        }.lessThan);
        return result;
    }
};

pub fn dupeAll(
    allocator: std.mem.Allocator,
    source: []const LanguageContribution,
) ![]LanguageContribution {
    const result = try allocator.alloc(LanguageContribution, source.len);
    var initialized: usize = 0;
    errdefer {
        for (result[0..initialized]) |language| language.deinit(allocator);
        allocator.free(result);
    }
    for (source, result) |src, *dest| {
        const name = try allocator.dupe(u8, src.name);
        errdefer allocator.free(name);
        const color = if (src.color) |color| try allocator.dupe(u8, color) else null;
        dest.* = .{
            .name = name,
            .color = color,
            .lines_changed = src.lines_changed,
        };
        initialized += 1;
    }
    return result;
}

test "Linguist classification covers exact filenames, extensions, and unknowns" {
    try std.testing.expectEqualStrings("C", classifyPath("src/main.c").?.name);
    try std.testing.expectEqualStrings("C", classifyPath("include/main.h").?.name);
    try std.testing.expectEqualStrings("Zig", classifyPath("src/main.zig").?.name);
    try std.testing.expectEqualStrings("Makefile", classifyPath("tools/Makefile").?.name);
    try std.testing.expectEqualStrings("HCL", classifyPath("infra/main.tf").?.name);
    try std.testing.expect(classifyPath("notes/unknown") == null);
    try std.testing.expect(classifyPath("package.json") == null);
    try std.testing.expect(classifyPath(".github/workflows/main.yml") == null);
    try std.testing.expect(classifyPath("README.md") == null);
    try std.testing.expect(classifyPath("ios/Pods/Library/native.cpp") == null);
    try std.testing.expect(classifyPath("node_modules/pkg/index.ts") == null);
    try std.testing.expect(classifyPath("ios/build/generated/main.swift") == null);
    try std.testing.expectEqualStrings("Zig", classifyPath("build.zig").?.name);
}

test "domain-like names and bare extensions are not misclassified" {
    // Domain-named directories or files should not match extension rules.
    try std.testing.expect(classifyPath("hackinggate.com") == null);
    try std.testing.expect(classifyPath("example.com") == null);
    // A bare extension name alone (no stem before the dot) should not match.
    try std.testing.expect(classifyPath(".c") == null);
    try std.testing.expect(classifyPath(".zig") == null);
    try std.testing.expect(classifyPath(".sh") == null);
    // But real filenames with these extensions still work.
    try std.testing.expectEqualStrings("C", classifyPath("foo.c").?.name);
    try std.testing.expectEqualStrings("Zig", classifyPath("foo.zig").?.name);
    try std.testing.expectEqualStrings("Shell", classifyPath("foo.sh").?.name);
    // Files inside domain-named directories classify by their own extension.
    try std.testing.expectEqualStrings("HTML", classifyPath("hackinggate.com/index.html").?.name);
    try std.testing.expectEqualStrings("JavaScript", classifyPath("example.com/app.js").?.name);
}

test "raw patch parser handles added, deleted, renamed, mixed, and header lines" {
    const patch =
        \\diff --git a/src/new.zig b/src/new.zig
        \\new file mode 100644
        \\--- /dev/null
        \\+++ b/src/new.zig
        \\@@ -0,0 +1,3 @@
        \\+const std = @import("std");
        \\+++ this is code, not a file header
        \\+\ No newline marker text in code
        \\diff --git a/src/old.c b/src/old.c
        \\deleted file mode 100644
        \\--- a/src/old.c
        \\+++ /dev/null
        \\@@ -1,2 +0,0 @@
        \\-int main(void) { return 0; }
        \\--- this is code, not a file header
        \\diff --git a/src/name.c b/src/name.zig
        \\similarity index 60%
        \\rename from src/name.c
        \\rename to src/name.zig
        \\--- a/src/name.c
        \\+++ b/src/name.zig
        \\@@ -1,2 +1,2 @@
        \\-int old(void) { return 1; }
        \\+pub fn new() u8 { return 1; }
        \\ context line
        \\diff --git a/web/app.js b/web/app.js
        \\--- a/web/app.js
        \\+++ b/web/app.js
        \\@@ -1,1 +1,1 @@
        \\-const a = 1;
        \\+const a = 2;
        \\diff --git a/image.bin b/image.bin
        \\new file mode 100644
        \\index 0000000..1111111
        \\Binary files /dev/null and b/image.bin differ
        \\
    ;
    const languages = try parsePatch(std.testing.allocator, patch);
    defer {
        for (languages) |language| language.deinit(std.testing.allocator);
        std.testing.allocator.free(languages);
    }
    try expectContribution(languages, "Zig", 4);
    try expectContribution(languages, "C", 3);
    try expectContribution(languages, "JavaScript", 2);
    try std.testing.expectEqual(@as(usize, 3), languages.len);
}

test "raw patch parser ignores file header and no-newline marker lines" {
    const patch =
        \\diff --git a/a.zig b/a.zig
        \\--- a/a.zig
        \\+++ b/a.zig
        \\@@ -1,2 +1,2 @@
        \\-old
        \\+new
        \\\ No newline at end of file
        \\
    ;
    const languages = try parsePatch(std.testing.allocator, patch);
    defer {
        for (languages) |language| language.deinit(std.testing.allocator);
        std.testing.allocator.free(languages);
    }
    try expectContribution(languages, "Zig", 2);
    try std.testing.expectEqual(@as(usize, 1), languages.len);
}

test "numstat parser counts additions and deletions by changed file language" {
    const languages = try parseNumstat(
        std.testing.allocator,
        "10\t2\tsrc/main.zig\n3\t4\tsrc/native.c\n99\t99\tios/Pods/lib/native.cpp\n-\t-\tassets/logo.png\n1\t1\tno_extension\n",
    );
    defer {
        for (languages) |language| language.deinit(std.testing.allocator);
        std.testing.allocator.free(languages);
    }
    try expectContribution(languages, "Zig", 12);
    try expectContribution(languages, "C", 7);
    try std.testing.expectEqual(@as(usize, 2), languages.len);
}

fn expectContribution(
    languages: []const LanguageContribution,
    name: []const u8,
    lines_changed: u32,
) !void {
    for (languages) |language| {
        if (std.mem.eql(u8, language.name, name)) {
            try std.testing.expectEqual(lines_changed, language.lines_changed);
            return;
        }
    }
    return error.ExpectedContributionMissing;
}
