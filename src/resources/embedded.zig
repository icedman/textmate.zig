// This is a generated file. Do not edit manually
const std = @import("std");
const res = @import("resources.zig");
const ThemeInfo = res.ThemeInfo;
const Allocator = std.mem.Allocator;

const theme_1 = @embedFile("themes/andromeeda.json");
const theme_2 = @embedFile("themes/aurora-x.json");
const theme_3 = @embedFile("themes/ayu-dark.json");
const theme_4 = @embedFile("themes/catppuccin-frappe.json");
const theme_5 = @embedFile("themes/catppuccin-latte.json");
const theme_6 = @embedFile("themes/catppuccin-macchiato.json");
const theme_7 = @embedFile("themes/catppuccin-mocha.json");
const theme_8 = @embedFile("themes/dark-plus.json");
const theme_9 = @embedFile("themes/dracula-soft.json");
const theme_10 = @embedFile("themes/dracula.json");
const theme_11 = @embedFile("themes/everforest-dark.json");
const theme_12 = @embedFile("themes/everforest-light.json");
const theme_13 = @embedFile("themes/github-dark-default.json");
const theme_14 = @embedFile("themes/github-dark-dimmed.json");
const theme_15 = @embedFile("themes/github-dark-high-contrast.json");
const theme_16 = @embedFile("themes/github-dark.json");
const theme_17 = @embedFile("themes/github-light-default.json");
const theme_18 = @embedFile("themes/github-light-high-contrast.json");
const theme_19 = @embedFile("themes/github-light.json");
const theme_20 = @embedFile("themes/gruvbox-dark-hard.json");
const theme_21 = @embedFile("themes/gruvbox-dark-medium.json");
const theme_22 = @embedFile("themes/gruvbox-dark-soft.json");
const theme_23 = @embedFile("themes/gruvbox-light-hard.json");
const theme_24 = @embedFile("themes/gruvbox-light-medium.json");
const theme_25 = @embedFile("themes/gruvbox-light-soft.json");
const theme_26 = @embedFile("themes/houston.json");
const theme_27 = @embedFile("themes/kanagawa-dragon.json");
const theme_28 = @embedFile("themes/kanagawa-lotus.json");
const theme_29 = @embedFile("themes/kanagawa-wave.json");
const theme_30 = @embedFile("themes/laserwave.json");
const theme_31 = @embedFile("themes/light-plus.json");
const theme_32 = @embedFile("themes/material-theme-darker.json");
const theme_33 = @embedFile("themes/material-theme-lighter.json");
const theme_34 = @embedFile("themes/material-theme-ocean.json");
const theme_35 = @embedFile("themes/material-theme-palenight.json");
const theme_36 = @embedFile("themes/material-theme.json");
const theme_37 = @embedFile("themes/min-dark.json");
const theme_38 = @embedFile("themes/min-light.json");
const theme_39 = @embedFile("themes/monokai.json");
const theme_40 = @embedFile("themes/night-owl.json");
const theme_41 = @embedFile("themes/nord.json");
const theme_42 = @embedFile("themes/one-dark-pro.json");
const theme_43 = @embedFile("themes/one-light.json");
const theme_44 = @embedFile("themes/plastic.json");
const theme_45 = @embedFile("themes/poimandres.json");
const theme_46 = @embedFile("themes/red.json");
const theme_47 = @embedFile("themes/rose-pine-dawn.json");
const theme_48 = @embedFile("themes/rose-pine-moon.json");
const theme_49 = @embedFile("themes/rose-pine.json");
const theme_50 = @embedFile("themes/slack-dark.json");
const theme_51 = @embedFile("themes/slack-ochin.json");
const theme_52 = @embedFile("themes/snazzy-light.json");
const theme_53 = @embedFile("themes/solarized-dark.json");
const theme_54 = @embedFile("themes/solarized-light.json");
const theme_55 = @embedFile("themes/synthwave-84.json");
const theme_56 = @embedFile("themes/tokyo-night.json");
const theme_57 = @embedFile("themes/vesper.json");
const theme_58 = @embedFile("themes/vitesse-black.json");
const theme_59 = @embedFile("themes/vitesse-dark.json");
const theme_60 = @embedFile("themes/vitesse-light.json");

pub fn listThemes(allocator: Allocator, list: *std.ArrayList(ThemeInfo)) !void {
    {
        const bytes: []const u8 = theme_1[0..theme_1.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."andromeeda".len], "andromeeda");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_2[0..theme_2.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."aurora-x".len], "aurora-x");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_3[0..theme_3.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."ayu-dark".len], "ayu-dark");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_4[0..theme_4.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."catppuccin-frappe".len], "catppuccin-frappe");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_5[0..theme_5.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."catppuccin-latte".len], "catppuccin-latte");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_6[0..theme_6.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."catppuccin-macchiato".len], "catppuccin-macchiato");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_7[0..theme_7.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."catppuccin-mocha".len], "catppuccin-mocha");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_8[0..theme_8.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."dark-plus".len], "dark-plus");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_9[0..theme_9.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."dracula-soft".len], "dracula-soft");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_10[0..theme_10.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."dracula".len], "dracula");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_11[0..theme_11.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."everforest-dark".len], "everforest-dark");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_12[0..theme_12.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."everforest-light".len], "everforest-light");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_13[0..theme_13.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."github-dark-default".len], "github-dark-default");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_14[0..theme_14.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."github-dark-dimmed".len], "github-dark-dimmed");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_15[0..theme_15.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."github-dark-high-contrast".len], "github-dark-high-contrast");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_16[0..theme_16.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."github-dark".len], "github-dark");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_17[0..theme_17.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."github-light-default".len], "github-light-default");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_18[0..theme_18.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."github-light-high-contrast".len], "github-light-high-contrast");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_19[0..theme_19.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."github-light".len], "github-light");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_20[0..theme_20.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."gruvbox-dark-hard".len], "gruvbox-dark-hard");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_21[0..theme_21.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."gruvbox-dark-medium".len], "gruvbox-dark-medium");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_22[0..theme_22.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."gruvbox-dark-soft".len], "gruvbox-dark-soft");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_23[0..theme_23.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."gruvbox-light-hard".len], "gruvbox-light-hard");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_24[0..theme_24.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."gruvbox-light-medium".len], "gruvbox-light-medium");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_25[0..theme_25.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."gruvbox-light-soft".len], "gruvbox-light-soft");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_26[0..theme_26.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."houston".len], "houston");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_27[0..theme_27.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."kanagawa-dragon".len], "kanagawa-dragon");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_28[0..theme_28.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."kanagawa-lotus".len], "kanagawa-lotus");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_29[0..theme_29.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."kanagawa-wave".len], "kanagawa-wave");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_30[0..theme_30.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."laserwave".len], "laserwave");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_31[0..theme_31.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."light-plus".len], "light-plus");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_32[0..theme_32.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."material-theme-darker".len], "material-theme-darker");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_33[0..theme_33.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."material-theme-lighter".len], "material-theme-lighter");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_34[0..theme_34.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."material-theme-ocean".len], "material-theme-ocean");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_35[0..theme_35.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."material-theme-palenight".len], "material-theme-palenight");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_36[0..theme_36.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."material-theme".len], "material-theme");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_37[0..theme_37.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."min-dark".len], "min-dark");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_38[0..theme_38.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."min-light".len], "min-light");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_39[0..theme_39.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."monokai".len], "monokai");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_40[0..theme_40.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."night-owl".len], "night-owl");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_41[0..theme_41.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."nord".len], "nord");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_42[0..theme_42.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."one-dark-pro".len], "one-dark-pro");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_43[0..theme_43.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."one-light".len], "one-light");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_44[0..theme_44.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."plastic".len], "plastic");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_45[0..theme_45.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."poimandres".len], "poimandres");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_46[0..theme_46.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."red".len], "red");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_47[0..theme_47.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."rose-pine-dawn".len], "rose-pine-dawn");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_48[0..theme_48.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."rose-pine-moon".len], "rose-pine-moon");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_49[0..theme_49.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."rose-pine".len], "rose-pine");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_50[0..theme_50.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."slack-dark".len], "slack-dark");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_51[0..theme_51.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."slack-ochin".len], "slack-ochin");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_52[0..theme_52.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."snazzy-light".len], "snazzy-light");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_53[0..theme_53.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."solarized-dark".len], "solarized-dark");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_54[0..theme_54.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."solarized-light".len], "solarized-light");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_55[0..theme_55.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."synthwave-84".len], "synthwave-84");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_56[0..theme_56.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."tokyo-night".len], "tokyo-night");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_57[0..theme_57.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."vesper".len], "vesper");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_58[0..theme_58.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."vitesse-black".len], "vitesse-black");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_59[0..theme_59.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."vitesse-dark".len], "vitesse-dark");
        try list.append(allocator, ti);
    }
    {
        const bytes: []const u8 = theme_60[0..theme_60.len];
        var ti = ThemeInfo{ .embedded_file = bytes };
        @memcpy(ti.name[0.."vitesse-light".len], "vitesse-light");
        try list.append(allocator, ti);
    }
}

const GrammarInfo = res.GrammarInfo;
const grammar_1 = @embedFile("grammars/abap.json");
const grammar_2 = @embedFile("grammars/actionscript-3.json");
const grammar_3 = @embedFile("grammars/ada.json");
const grammar_4 = @embedFile("grammars/angular-expression.json");
const grammar_5 = @embedFile("grammars/angular-html.json");
const grammar_6 = @embedFile("grammars/angular-inline-style.json");
const grammar_7 = @embedFile("grammars/angular-inline-template.json");
const grammar_8 = @embedFile("grammars/angular-let-declaration.json");
const grammar_9 = @embedFile("grammars/angular-template-blocks.json");
const grammar_10 = @embedFile("grammars/angular-template.json");
const grammar_11 = @embedFile("grammars/angular-ts.json");
const grammar_12 = @embedFile("grammars/apache.json");
const grammar_13 = @embedFile("grammars/apex.json");
const grammar_14 = @embedFile("grammars/apl.json");
const grammar_15 = @embedFile("grammars/applescript.json");
const grammar_16 = @embedFile("grammars/ara.json");
const grammar_17 = @embedFile("grammars/asciidoc.json");
const grammar_18 = @embedFile("grammars/asm.json");
const grammar_19 = @embedFile("grammars/astro.json");
const grammar_20 = @embedFile("grammars/awk.json");
const grammar_21 = @embedFile("grammars/ballerina.json");
const grammar_22 = @embedFile("grammars/bat.json");
const grammar_23 = @embedFile("grammars/beancount.json");
const grammar_24 = @embedFile("grammars/berry.json");
const grammar_25 = @embedFile("grammars/bibtex.json");
const grammar_26 = @embedFile("grammars/bicep.json");
const grammar_27 = @embedFile("grammars/blade.json");
const grammar_28 = @embedFile("grammars/bsl.json");
const grammar_29 = @embedFile("grammars/c.json");
const grammar_30 = @embedFile("grammars/cadence.json");
const grammar_31 = @embedFile("grammars/cairo.json");
const grammar_32 = @embedFile("grammars/clarity.json");
const grammar_33 = @embedFile("grammars/clojure.json");
const grammar_34 = @embedFile("grammars/cmake.json");
const grammar_35 = @embedFile("grammars/cobol.json");
const grammar_36 = @embedFile("grammars/codeowners.json");
const grammar_37 = @embedFile("grammars/codeql.json");
const grammar_38 = @embedFile("grammars/coffee.json");
const grammar_39 = @embedFile("grammars/common-lisp.json");
const grammar_40 = @embedFile("grammars/coq.json");
const grammar_41 = @embedFile("grammars/cpp-macro.json");
const grammar_42 = @embedFile("grammars/cpp.json");
const grammar_43 = @embedFile("grammars/crystal.json");
const grammar_44 = @embedFile("grammars/csharp.json");
const grammar_45 = @embedFile("grammars/css.json");
const grammar_46 = @embedFile("grammars/csv.json");
const grammar_47 = @embedFile("grammars/cue.json");
const grammar_48 = @embedFile("grammars/cypher.json");
const grammar_49 = @embedFile("grammars/d.json");
const grammar_50 = @embedFile("grammars/dart.json");
const grammar_51 = @embedFile("grammars/dax.json");
const grammar_52 = @embedFile("grammars/desktop.json");
const grammar_53 = @embedFile("grammars/diff.json");
const grammar_54 = @embedFile("grammars/docker.json");
const grammar_55 = @embedFile("grammars/dotenv.json");
const grammar_56 = @embedFile("grammars/dream-maker.json");
const grammar_57 = @embedFile("grammars/edge.json");
const grammar_58 = @embedFile("grammars/elixir.json");
const grammar_59 = @embedFile("grammars/elm.json");
const grammar_60 = @embedFile("grammars/emacs-lisp.json");
const grammar_61 = @embedFile("grammars/erb.json");
const grammar_62 = @embedFile("grammars/erlang.json");
const grammar_63 = @embedFile("grammars/es-tag-css.json");
const grammar_64 = @embedFile("grammars/es-tag-glsl.json");
const grammar_65 = @embedFile("grammars/es-tag-html.json");
const grammar_66 = @embedFile("grammars/es-tag-sql.json");
const grammar_67 = @embedFile("grammars/es-tag-xml.json");
const grammar_68 = @embedFile("grammars/fennel.json");
const grammar_69 = @embedFile("grammars/fish.json");
const grammar_70 = @embedFile("grammars/fluent.json");
const grammar_71 = @embedFile("grammars/fortran-fixed-form.json");
const grammar_72 = @embedFile("grammars/fortran-free-form.json");
const grammar_73 = @embedFile("grammars/fsharp.json");
const grammar_74 = @embedFile("grammars/gdresource.json");
const grammar_75 = @embedFile("grammars/gdscript.json");
const grammar_76 = @embedFile("grammars/gdshader.json");
const grammar_77 = @embedFile("grammars/genie.json");
const grammar_78 = @embedFile("grammars/gherkin.json");
const grammar_79 = @embedFile("grammars/git-commit.json");
const grammar_80 = @embedFile("grammars/git-rebase.json");
const grammar_81 = @embedFile("grammars/gleam.json");
const grammar_82 = @embedFile("grammars/glimmer-js.json");
const grammar_83 = @embedFile("grammars/glimmer-ts.json");
const grammar_84 = @embedFile("grammars/glsl.json");
const grammar_85 = @embedFile("grammars/gnuplot.json");
const grammar_86 = @embedFile("grammars/go.json");
const grammar_87 = @embedFile("grammars/graphql.json");
const grammar_88 = @embedFile("grammars/groovy.json");
const grammar_89 = @embedFile("grammars/hack.json");
const grammar_90 = @embedFile("grammars/haml.json");
const grammar_91 = @embedFile("grammars/handlebars.json");
const grammar_92 = @embedFile("grammars/haskell.json");
const grammar_93 = @embedFile("grammars/haxe.json");
const grammar_94 = @embedFile("grammars/hcl.json");
const grammar_95 = @embedFile("grammars/hjson.json");
const grammar_96 = @embedFile("grammars/hlsl.json");
const grammar_97 = @embedFile("grammars/html-derivative.json");
const grammar_98 = @embedFile("grammars/html.json");
const grammar_99 = @embedFile("grammars/http.json");
const grammar_100 = @embedFile("grammars/hxml.json");
const grammar_101 = @embedFile("grammars/hy.json");
const grammar_102 = @embedFile("grammars/imba.json");
const grammar_103 = @embedFile("grammars/ini.json");
const grammar_104 = @embedFile("grammars/java.json");
const grammar_105 = @embedFile("grammars/javascript.json");
const grammar_106 = @embedFile("grammars/jinja-html.json");
const grammar_107 = @embedFile("grammars/jinja.json");
const grammar_108 = @embedFile("grammars/jison.json");
const grammar_109 = @embedFile("grammars/json.json");
const grammar_110 = @embedFile("grammars/json5.json");
const grammar_111 = @embedFile("grammars/jsonc.json");
const grammar_112 = @embedFile("grammars/jsonl.json");
const grammar_113 = @embedFile("grammars/jsonnet.json");
const grammar_114 = @embedFile("grammars/jssm.json");
const grammar_115 = @embedFile("grammars/jsx.json");
const grammar_116 = @embedFile("grammars/julia.json");
const grammar_117 = @embedFile("grammars/kotlin.json");
const grammar_118 = @embedFile("grammars/kusto.json");
const grammar_119 = @embedFile("grammars/latex.json");
const grammar_120 = @embedFile("grammars/lean.json");
const grammar_121 = @embedFile("grammars/less.json");
const grammar_122 = @embedFile("grammars/liquid.json");
const grammar_123 = @embedFile("grammars/llvm.json");
const grammar_124 = @embedFile("grammars/log.json");
const grammar_125 = @embedFile("grammars/logo.json");
const grammar_126 = @embedFile("grammars/lua.json");
const grammar_127 = @embedFile("grammars/luau.json");
const grammar_128 = @embedFile("grammars/make.json");
const grammar_129 = @embedFile("grammars/markdown-vue.json");
const grammar_130 = @embedFile("grammars/markdown.json");
const grammar_131 = @embedFile("grammars/marko.json");
const grammar_132 = @embedFile("grammars/matlab.json");
const grammar_133 = @embedFile("grammars/mdc.json");
const grammar_134 = @embedFile("grammars/mdx.json");
const grammar_135 = @embedFile("grammars/mermaid.json");
const grammar_136 = @embedFile("grammars/mipsasm.json");
const grammar_137 = @embedFile("grammars/mojo.json");
const grammar_138 = @embedFile("grammars/move.json");
const grammar_139 = @embedFile("grammars/narrat.json");
const grammar_140 = @embedFile("grammars/nextflow.json");
const grammar_141 = @embedFile("grammars/nginx.json");
const grammar_142 = @embedFile("grammars/nim.json");
const grammar_143 = @embedFile("grammars/nix.json");
const grammar_144 = @embedFile("grammars/nushell.json");
const grammar_145 = @embedFile("grammars/objective-c.json");
const grammar_146 = @embedFile("grammars/objective-cpp.json");
const grammar_147 = @embedFile("grammars/ocaml.json");
const grammar_148 = @embedFile("grammars/pascal.json");
const grammar_149 = @embedFile("grammars/perl.json");
const grammar_150 = @embedFile("grammars/php.json");
const grammar_151 = @embedFile("grammars/plsql.json");
const grammar_152 = @embedFile("grammars/po.json");
const grammar_153 = @embedFile("grammars/polar.json");
const grammar_154 = @embedFile("grammars/postcss.json");
const grammar_155 = @embedFile("grammars/powerquery.json");
const grammar_156 = @embedFile("grammars/powershell.json");
const grammar_157 = @embedFile("grammars/prisma.json");
const grammar_158 = @embedFile("grammars/prolog.json");
const grammar_159 = @embedFile("grammars/proto.json");
const grammar_160 = @embedFile("grammars/pug.json");
const grammar_161 = @embedFile("grammars/puppet.json");
const grammar_162 = @embedFile("grammars/purescript.json");
const grammar_163 = @embedFile("grammars/python.json");
const grammar_164 = @embedFile("grammars/qml.json");
const grammar_165 = @embedFile("grammars/qmldir.json");
const grammar_166 = @embedFile("grammars/qss.json");
const grammar_167 = @embedFile("grammars/r.json");
const grammar_168 = @embedFile("grammars/racket.json");
const grammar_169 = @embedFile("grammars/raku.json");
const grammar_170 = @embedFile("grammars/razor.json");
const grammar_171 = @embedFile("grammars/reg.json");
const grammar_172 = @embedFile("grammars/regexp.json");
const grammar_173 = @embedFile("grammars/rel.json");
const grammar_174 = @embedFile("grammars/riscv.json");
const grammar_175 = @embedFile("grammars/rst.json");
const grammar_176 = @embedFile("grammars/ruby.json");
const grammar_177 = @embedFile("grammars/rust.json");
const grammar_178 = @embedFile("grammars/sas.json");
const grammar_179 = @embedFile("grammars/sass.json");
const grammar_180 = @embedFile("grammars/scala.json");
const grammar_181 = @embedFile("grammars/scheme.json");
const grammar_182 = @embedFile("grammars/scss.json");
const grammar_183 = @embedFile("grammars/sdbl.json");
const grammar_184 = @embedFile("grammars/shaderlab.json");
const grammar_185 = @embedFile("grammars/shellscript.json");
const grammar_186 = @embedFile("grammars/shellsession.json");
const grammar_187 = @embedFile("grammars/smalltalk.json");
const grammar_188 = @embedFile("grammars/solidity.json");
const grammar_189 = @embedFile("grammars/soy.json");
const grammar_190 = @embedFile("grammars/sparql.json");
const grammar_191 = @embedFile("grammars/splunk.json");
const grammar_192 = @embedFile("grammars/sql.json");
const grammar_193 = @embedFile("grammars/ssh-config.json");
const grammar_194 = @embedFile("grammars/stata.json");
const grammar_195 = @embedFile("grammars/stylus.json");
const grammar_196 = @embedFile("grammars/svelte.json");
const grammar_197 = @embedFile("grammars/swift.json");
const grammar_198 = @embedFile("grammars/system-verilog.json");
const grammar_199 = @embedFile("grammars/systemd.json");
const grammar_200 = @embedFile("grammars/talonscript.json");
const grammar_201 = @embedFile("grammars/tasl.json");
const grammar_202 = @embedFile("grammars/tcl.json");
const grammar_203 = @embedFile("grammars/templ.json");
const grammar_204 = @embedFile("grammars/terraform.json");
const grammar_205 = @embedFile("grammars/tex.json");
const grammar_206 = @embedFile("grammars/toml.json");
const grammar_207 = @embedFile("grammars/ts-tags.json");
const grammar_208 = @embedFile("grammars/tsv.json");
const grammar_209 = @embedFile("grammars/tsx.json");
const grammar_210 = @embedFile("grammars/turtle.json");
const grammar_211 = @embedFile("grammars/twig.json");
const grammar_212 = @embedFile("grammars/typescript.json");
const grammar_213 = @embedFile("grammars/typespec.json");
const grammar_214 = @embedFile("grammars/typst.json");
const grammar_215 = @embedFile("grammars/v.json");
const grammar_216 = @embedFile("grammars/vala.json");
const grammar_217 = @embedFile("grammars/vb.json");
const grammar_218 = @embedFile("grammars/verilog.json");
const grammar_219 = @embedFile("grammars/vhdl.json");
const grammar_220 = @embedFile("grammars/viml.json");
const grammar_221 = @embedFile("grammars/vue-directives.json");
const grammar_222 = @embedFile("grammars/vue-html.json");
const grammar_223 = @embedFile("grammars/vue-interpolations.json");
const grammar_224 = @embedFile("grammars/vue-sfc-style-variable-injection.json");
const grammar_225 = @embedFile("grammars/vue-vine.json");
const grammar_226 = @embedFile("grammars/vue.json");
const grammar_227 = @embedFile("grammars/vyper.json");
const grammar_228 = @embedFile("grammars/wasm.json");
const grammar_229 = @embedFile("grammars/wenyan.json");
const grammar_230 = @embedFile("grammars/wgsl.json");
const grammar_231 = @embedFile("grammars/wikitext.json");
const grammar_232 = @embedFile("grammars/wit.json");
const grammar_233 = @embedFile("grammars/wolfram.json");
const grammar_234 = @embedFile("grammars/xml.json");
const grammar_235 = @embedFile("grammars/xsl.json");
const grammar_236 = @embedFile("grammars/yaml.json");
const grammar_237 = @embedFile("grammars/zenscript.json");
const grammar_238 = @embedFile("grammars/zig.json");

pub fn listGrammars(allocator: Allocator, list: *std.ArrayList(GrammarInfo)) !void {
    {
        const bytes: []const u8 = grammar_1[0..grammar_1.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."abap".len], "abap");
        @memcpy(gi.scope_name[0.."source.abap".len], "source.abap");
        @memcpy(gi.file_types[0][0.."abap".len], "abap");
        @memcpy(gi.file_types[1][0.."ABAP".len], "ABAP");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_2[0..grammar_2.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."actionscript-3".len], "actionscript-3");
        @memcpy(gi.scope_name[0.."source.actionscript.3".len], "source.actionscript.3");
        @memcpy(gi.file_types[0][0.."as".len], "as");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_3[0..grammar_3.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."ada".len], "ada");
        @memcpy(gi.scope_name[0.."source.ada".len], "source.ada");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_4[0..grammar_4.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."angular-expression".len], "angular-expression");
        @memcpy(gi.scope_name[0.."expression.ng".len], "expression.ng");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_5[0..grammar_5.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."angular-html".len], "angular-html");
        @memcpy(gi.scope_name[0.."text.html.derivative.ng".len], "text.html.derivative.ng");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_6[0..grammar_6.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = true };
        @memcpy(gi.name[0.."angular-inline-style".len], "angular-inline-style");
        @memcpy(gi.scope_name[0.."inline-styles.ng".len], "inline-styles.ng");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_7[0..grammar_7.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = true };
        @memcpy(gi.name[0.."angular-inline-template".len], "angular-inline-template");
        @memcpy(gi.scope_name[0.."inline-template.ng".len], "inline-template.ng");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_8[0..grammar_8.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = true };
        @memcpy(gi.name[0.."angular-let-declaration".len], "angular-let-declaration");
        @memcpy(gi.scope_name[0.."template.let.ng".len], "template.let.ng");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_9[0..grammar_9.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = true };
        @memcpy(gi.name[0.."angular-template-blocks".len], "angular-template-blocks");
        @memcpy(gi.scope_name[0.."template.blocks.ng".len], "template.blocks.ng");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_10[0..grammar_10.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = true };
        @memcpy(gi.name[0.."angular-template".len], "angular-template");
        @memcpy(gi.scope_name[0.."template.ng".len], "template.ng");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_11[0..grammar_11.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."angular-ts".len], "angular-ts");
        @memcpy(gi.scope_name[0.."source.ts.ng".len], "source.ts.ng");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_12[0..grammar_12.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 8, .inject_only = false };
        @memcpy(gi.name[0.."apache".len], "apache");
        @memcpy(gi.scope_name[0.."source.apacheconf".len], "source.apacheconf");
        @memcpy(gi.file_types[0][0.."conf".len], "conf");
        @memcpy(gi.file_types[1][0.."CONF".len], "CONF");
        @memcpy(gi.file_types[2][0.."envvars".len], "envvars");
        @memcpy(gi.file_types[3][0.."htaccess".len], "htaccess");
        @memcpy(gi.file_types[4][0.."HTACCESS".len], "HTACCESS");
        @memcpy(gi.file_types[5][0.."htgroups".len], "htgroups");
        @memcpy(gi.file_types[6][0.."HTGROUPS".len], "HTGROUPS");
        @memcpy(gi.file_types[7][0.."htpasswd".len], "htpasswd");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_13[0..grammar_13.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 3, .inject_only = false };
        @memcpy(gi.name[0.."apex".len], "apex");
        @memcpy(gi.scope_name[0.."source.apex".len], "source.apex");
        @memcpy(gi.file_types[0][0.."apex".len], "apex");
        @memcpy(gi.file_types[1][0.."cls".len], "cls");
        @memcpy(gi.file_types[2][0.."trigger".len], "trigger");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_14[0..grammar_14.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 8, .inject_only = false };
        @memcpy(gi.name[0.."apl".len], "apl");
        @memcpy(gi.scope_name[0.."source.apl".len], "source.apl");
        @memcpy(gi.file_types[0][0.."apl".len], "apl");
        @memcpy(gi.file_types[1][0.."apla".len], "apla");
        @memcpy(gi.file_types[2][0.."aplc".len], "aplc");
        @memcpy(gi.file_types[3][0.."aplf".len], "aplf");
        @memcpy(gi.file_types[4][0.."apli".len], "apli");
        @memcpy(gi.file_types[5][0.."apln".len], "apln");
        @memcpy(gi.file_types[6][0.."aplo".len], "aplo");
        @memcpy(gi.file_types[7][0.."dyalog".len], "dyalog");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_15[0..grammar_15.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 3, .inject_only = false };
        @memcpy(gi.name[0.."applescript".len], "applescript");
        @memcpy(gi.scope_name[0.."source.applescript".len], "source.applescript");
        @memcpy(gi.file_types[0][0.."applescript".len], "applescript");
        @memcpy(gi.file_types[1][0.."scpt".len], "scpt");
        @memcpy(gi.file_types[2][0.."script editor".len], "script editor");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_16[0..grammar_16.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."ara".len], "ara");
        @memcpy(gi.scope_name[0.."source.ara".len], "source.ara");
        @memcpy(gi.file_types[0][0.."ara".len], "ara");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_17[0..grammar_17.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 5, .inject_only = false };
        @memcpy(gi.name[0.."asciidoc".len], "asciidoc");
        @memcpy(gi.scope_name[0.."text.asciidoc".len], "text.asciidoc");
        @memcpy(gi.file_types[0][0.."ad".len], "ad");
        @memcpy(gi.file_types[1][0.."asc".len], "asc");
        @memcpy(gi.file_types[2][0.."adoc".len], "adoc");
        @memcpy(gi.file_types[3][0.."asciidoc".len], "asciidoc");
        @memcpy(gi.file_types[4][0.."adoc.txt".len], "adoc.txt");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_18[0..grammar_18.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 5, .inject_only = false };
        @memcpy(gi.name[0.."asm".len], "asm");
        @memcpy(gi.scope_name[0.."source.asm.x86_64".len], "source.asm.x86_64");
        @memcpy(gi.file_types[0][0.."asm".len], "asm");
        @memcpy(gi.file_types[1][0.."nasm".len], "nasm");
        @memcpy(gi.file_types[2][0.."yasm".len], "yasm");
        @memcpy(gi.file_types[3][0.."inc".len], "inc");
        @memcpy(gi.file_types[4][0.."s".len], "s");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_19[0..grammar_19.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."astro".len], "astro");
        @memcpy(gi.scope_name[0.."source.astro".len], "source.astro");
        @memcpy(gi.file_types[0][0.."astro".len], "astro");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_20[0..grammar_20.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."awk".len], "awk");
        @memcpy(gi.scope_name[0.."source.awk".len], "source.awk");
        @memcpy(gi.file_types[0][0.."awk".len], "awk");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_21[0..grammar_21.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."ballerina".len], "ballerina");
        @memcpy(gi.scope_name[0.."source.ballerina".len], "source.ballerina");
        @memcpy(gi.file_types[0][0.."bal".len], "bal");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_22[0..grammar_22.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."bat".len], "bat");
        @memcpy(gi.scope_name[0.."source.batchfile".len], "source.batchfile");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_23[0..grammar_23.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."beancount".len], "beancount");
        @memcpy(gi.scope_name[0.."text.beancount".len], "text.beancount");
        @memcpy(gi.file_types[0][0.."beancount".len], "beancount");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_24[0..grammar_24.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."berry".len], "berry");
        @memcpy(gi.scope_name[0.."source.berry".len], "source.berry");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_25[0..grammar_25.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."bibtex".len], "bibtex");
        @memcpy(gi.scope_name[0.."text.bibtex".len], "text.bibtex");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_26[0..grammar_26.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."bicep".len], "bicep");
        @memcpy(gi.scope_name[0.."source.bicep".len], "source.bicep");
        @memcpy(gi.file_types[0][0..".bicep".len], ".bicep");
        @memcpy(gi.file_types[1][0..".bicepparam".len], ".bicepparam");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_27[0..grammar_27.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."blade".len], "blade");
        @memcpy(gi.scope_name[0.."text.html.php.blade".len], "text.html.php.blade");
        @memcpy(gi.file_types[0][0.."blade.php".len], "blade.php");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_28[0..grammar_28.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."bsl".len], "bsl");
        @memcpy(gi.scope_name[0.."source.bsl".len], "source.bsl");
        @memcpy(gi.file_types[0][0.."bsl".len], "bsl");
        @memcpy(gi.file_types[1][0.."os".len], "os");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_29[0..grammar_29.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."c".len], "c");
        @memcpy(gi.scope_name[0.."source.c".len], "source.c");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_30[0..grammar_30.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."cadence".len], "cadence");
        @memcpy(gi.scope_name[0.."source.cadence".len], "source.cadence");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_31[0..grammar_31.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."cairo".len], "cairo");
        @memcpy(gi.scope_name[0.."source.cairo0".len], "source.cairo0");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_32[0..grammar_32.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."clarity".len], "clarity");
        @memcpy(gi.scope_name[0.."source.clar".len], "source.clar");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_33[0..grammar_33.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."clojure".len], "clojure");
        @memcpy(gi.scope_name[0.."source.clojure".len], "source.clojure");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_34[0..grammar_34.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."cmake".len], "cmake");
        @memcpy(gi.scope_name[0.."source.cmake".len], "source.cmake");
        @memcpy(gi.file_types[0][0.."cmake".len], "cmake");
        @memcpy(gi.file_types[1][0.."CMakeLists.txt".len], "CMakeLists.txt");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_35[0..grammar_35.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 8, .inject_only = false };
        @memcpy(gi.name[0.."cobol".len], "cobol");
        @memcpy(gi.scope_name[0.."source.cobol".len], "source.cobol");
        @memcpy(gi.file_types[0][0.."ccp".len], "ccp");
        @memcpy(gi.file_types[1][0.."scbl".len], "scbl");
        @memcpy(gi.file_types[2][0.."cobol".len], "cobol");
        @memcpy(gi.file_types[3][0.."cbl".len], "cbl");
        @memcpy(gi.file_types[4][0.."cblle".len], "cblle");
        @memcpy(gi.file_types[5][0.."cblsrce".len], "cblsrce");
        @memcpy(gi.file_types[6][0.."cblcpy".len], "cblcpy");
        @memcpy(gi.file_types[7][0.."lks".len], "lks");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_36[0..grammar_36.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."codeowners".len], "codeowners");
        @memcpy(gi.scope_name[0.."text.codeowners".len], "text.codeowners");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_37[0..grammar_37.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."codeql".len], "codeql");
        @memcpy(gi.scope_name[0.."source.ql".len], "source.ql");
        @memcpy(gi.file_types[0][0.."ql".len], "ql");
        @memcpy(gi.file_types[1][0.."qll".len], "qll");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_38[0..grammar_38.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."coffee".len], "coffee");
        @memcpy(gi.scope_name[0.."source.coffee".len], "source.coffee");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_39[0..grammar_39.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 6, .inject_only = false };
        @memcpy(gi.name[0.."common-lisp".len], "common-lisp");
        @memcpy(gi.scope_name[0.."source.commonlisp".len], "source.commonlisp");
        @memcpy(gi.file_types[0][0.."lisp".len], "lisp");
        @memcpy(gi.file_types[1][0.."lsp".len], "lsp");
        @memcpy(gi.file_types[2][0.."l".len], "l");
        @memcpy(gi.file_types[3][0.."cl".len], "cl");
        @memcpy(gi.file_types[4][0.."asd".len], "asd");
        @memcpy(gi.file_types[5][0.."asdf".len], "asdf");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_40[0..grammar_40.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."coq".len], "coq");
        @memcpy(gi.scope_name[0.."source.coq".len], "source.coq");
        @memcpy(gi.file_types[0][0.."v".len], "v");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_41[0..grammar_41.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."cpp-macro".len], "cpp-macro");
        @memcpy(gi.scope_name[0.."source.cpp.embedded.macro".len], "source.cpp.embedded.macro");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_42[0..grammar_42.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."cpp".len], "cpp");
        @memcpy(gi.scope_name[0.."source.cpp".len], "source.cpp");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_43[0..grammar_43.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."crystal".len], "crystal");
        @memcpy(gi.scope_name[0.."source.crystal".len], "source.crystal");
        @memcpy(gi.file_types[0][0.."cr".len], "cr");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_44[0..grammar_44.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."csharp".len], "csharp");
        @memcpy(gi.scope_name[0.."source.cs".len], "source.cs");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_45[0..grammar_45.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."css".len], "css");
        @memcpy(gi.scope_name[0.."source.css".len], "source.css");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_46[0..grammar_46.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."csv".len], "csv");
        @memcpy(gi.scope_name[0.."text.csv".len], "text.csv");
        @memcpy(gi.file_types[0][0.."csv".len], "csv");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_47[0..grammar_47.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."cue".len], "cue");
        @memcpy(gi.scope_name[0.."source.cue".len], "source.cue");
        @memcpy(gi.file_types[0][0.."cue".len], "cue");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_48[0..grammar_48.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 3, .inject_only = false };
        @memcpy(gi.name[0.."cypher".len], "cypher");
        @memcpy(gi.scope_name[0.."source.cypher".len], "source.cypher");
        @memcpy(gi.file_types[0][0.."cql".len], "cql");
        @memcpy(gi.file_types[1][0.."cyp".len], "cyp");
        @memcpy(gi.file_types[2][0.."cypher".len], "cypher");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_49[0..grammar_49.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 3, .inject_only = false };
        @memcpy(gi.name[0.."d".len], "d");
        @memcpy(gi.scope_name[0.."source.d".len], "source.d");
        @memcpy(gi.file_types[0][0.."d".len], "d");
        @memcpy(gi.file_types[1][0.."di".len], "di");
        @memcpy(gi.file_types[2][0.."dpp".len], "dpp");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_50[0..grammar_50.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."dart".len], "dart");
        @memcpy(gi.scope_name[0.."source.dart".len], "source.dart");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_51[0..grammar_51.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."dax".len], "dax");
        @memcpy(gi.scope_name[0.."source.dax".len], "source.dax");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_52[0..grammar_52.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."desktop".len], "desktop");
        @memcpy(gi.scope_name[0.."source.desktop".len], "source.desktop");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_53[0..grammar_53.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."diff".len], "diff");
        @memcpy(gi.scope_name[0.."source.diff".len], "source.diff");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_54[0..grammar_54.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."docker".len], "docker");
        @memcpy(gi.scope_name[0.."source.dockerfile".len], "source.dockerfile");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_55[0..grammar_55.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."dotenv".len], "dotenv");
        @memcpy(gi.scope_name[0.."source.dotenv".len], "source.dotenv");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_56[0..grammar_56.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."dream-maker".len], "dream-maker");
        @memcpy(gi.scope_name[0.."source.dm".len], "source.dm");
        @memcpy(gi.file_types[0][0.."dm".len], "dm");
        @memcpy(gi.file_types[1][0.."dme".len], "dme");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_57[0..grammar_57.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."edge".len], "edge");
        @memcpy(gi.scope_name[0.."text.html.edge".len], "text.html.edge");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_58[0..grammar_58.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."elixir".len], "elixir");
        @memcpy(gi.scope_name[0.."source.elixir".len], "source.elixir");
        @memcpy(gi.file_types[0][0.."ex".len], "ex");
        @memcpy(gi.file_types[1][0.."exs".len], "exs");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_59[0..grammar_59.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."elm".len], "elm");
        @memcpy(gi.scope_name[0.."source.elm".len], "source.elm");
        @memcpy(gi.file_types[0][0.."elm".len], "elm");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_60[0..grammar_60.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 8, .inject_only = false };
        @memcpy(gi.name[0.."emacs-lisp".len], "emacs-lisp");
        @memcpy(gi.scope_name[0.."source.emacs.lisp".len], "source.emacs.lisp");
        @memcpy(gi.file_types[0][0.."el".len], "el");
        @memcpy(gi.file_types[1][0.."elc".len], "elc");
        @memcpy(gi.file_types[2][0.."eld".len], "eld");
        @memcpy(gi.file_types[3][0.."spacemacs".len], "spacemacs");
        @memcpy(gi.file_types[4][0.."_emacs".len], "_emacs");
        @memcpy(gi.file_types[5][0.."emacs".len], "emacs");
        @memcpy(gi.file_types[6][0.."emacs.desktop".len], "emacs.desktop");
        @memcpy(gi.file_types[7][0.."abbrev_defs".len], "abbrev_defs");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_61[0..grammar_61.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 3, .inject_only = false };
        @memcpy(gi.name[0.."erb".len], "erb");
        @memcpy(gi.scope_name[0.."text.html.erb".len], "text.html.erb");
        @memcpy(gi.file_types[0][0.."erb".len], "erb");
        @memcpy(gi.file_types[1][0.."rhtml".len], "rhtml");
        @memcpy(gi.file_types[2][0.."html.erb".len], "html.erb");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_62[0..grammar_62.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 5, .inject_only = false };
        @memcpy(gi.name[0.."erlang".len], "erlang");
        @memcpy(gi.scope_name[0.."source.erlang".len], "source.erlang");
        @memcpy(gi.file_types[0][0.."erl".len], "erl");
        @memcpy(gi.file_types[1][0.."escript".len], "escript");
        @memcpy(gi.file_types[2][0.."hrl".len], "hrl");
        @memcpy(gi.file_types[3][0.."xrl".len], "xrl");
        @memcpy(gi.file_types[4][0.."yrl".len], "yrl");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_63[0..grammar_63.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 8, .inject_only = true };
        @memcpy(gi.name[0.."es-tag-css".len], "es-tag-css");
        @memcpy(gi.scope_name[0.."inline.es6-css".len], "inline.es6-css");
        @memcpy(gi.file_types[0][0.."js".len], "js");
        @memcpy(gi.file_types[1][0.."jsx".len], "jsx");
        @memcpy(gi.file_types[2][0.."ts".len], "ts");
        @memcpy(gi.file_types[3][0.."tsx".len], "tsx");
        @memcpy(gi.file_types[4][0.."html".len], "html");
        @memcpy(gi.file_types[5][0.."vue".len], "vue");
        @memcpy(gi.file_types[6][0.."svelte".len], "svelte");
        @memcpy(gi.file_types[7][0.."php".len], "php");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_64[0..grammar_64.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 8, .inject_only = true };
        @memcpy(gi.name[0.."es-tag-glsl".len], "es-tag-glsl");
        @memcpy(gi.scope_name[0.."inline.es6-glsl".len], "inline.es6-glsl");
        @memcpy(gi.file_types[0][0.."js".len], "js");
        @memcpy(gi.file_types[1][0.."jsx".len], "jsx");
        @memcpy(gi.file_types[2][0.."ts".len], "ts");
        @memcpy(gi.file_types[3][0.."tsx".len], "tsx");
        @memcpy(gi.file_types[4][0.."html".len], "html");
        @memcpy(gi.file_types[5][0.."vue".len], "vue");
        @memcpy(gi.file_types[6][0.."svelte".len], "svelte");
        @memcpy(gi.file_types[7][0.."php".len], "php");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_65[0..grammar_65.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 8, .inject_only = true };
        @memcpy(gi.name[0.."es-tag-html".len], "es-tag-html");
        @memcpy(gi.scope_name[0.."inline.es6-html".len], "inline.es6-html");
        @memcpy(gi.file_types[0][0.."js".len], "js");
        @memcpy(gi.file_types[1][0.."jsx".len], "jsx");
        @memcpy(gi.file_types[2][0.."ts".len], "ts");
        @memcpy(gi.file_types[3][0.."tsx".len], "tsx");
        @memcpy(gi.file_types[4][0.."html".len], "html");
        @memcpy(gi.file_types[5][0.."vue".len], "vue");
        @memcpy(gi.file_types[6][0.."svelte".len], "svelte");
        @memcpy(gi.file_types[7][0.."php".len], "php");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_66[0..grammar_66.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 8, .inject_only = true };
        @memcpy(gi.name[0.."es-tag-sql".len], "es-tag-sql");
        @memcpy(gi.scope_name[0.."inline.es6-sql".len], "inline.es6-sql");
        @memcpy(gi.file_types[0][0.."js".len], "js");
        @memcpy(gi.file_types[1][0.."jsx".len], "jsx");
        @memcpy(gi.file_types[2][0.."ts".len], "ts");
        @memcpy(gi.file_types[3][0.."tsx".len], "tsx");
        @memcpy(gi.file_types[4][0.."html".len], "html");
        @memcpy(gi.file_types[5][0.."vue".len], "vue");
        @memcpy(gi.file_types[6][0.."svelte".len], "svelte");
        @memcpy(gi.file_types[7][0.."php".len], "php");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_67[0..grammar_67.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 8, .inject_only = true };
        @memcpy(gi.name[0.."es-tag-xml".len], "es-tag-xml");
        @memcpy(gi.scope_name[0.."inline.es6-xml".len], "inline.es6-xml");
        @memcpy(gi.file_types[0][0.."js".len], "js");
        @memcpy(gi.file_types[1][0.."jsx".len], "jsx");
        @memcpy(gi.file_types[2][0.."ts".len], "ts");
        @memcpy(gi.file_types[3][0.."tsx".len], "tsx");
        @memcpy(gi.file_types[4][0.."html".len], "html");
        @memcpy(gi.file_types[5][0.."vue".len], "vue");
        @memcpy(gi.file_types[6][0.."svelte".len], "svelte");
        @memcpy(gi.file_types[7][0.."php".len], "php");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_68[0..grammar_68.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."fennel".len], "fennel");
        @memcpy(gi.scope_name[0.."source.fnl".len], "source.fnl");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_69[0..grammar_69.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."fish".len], "fish");
        @memcpy(gi.scope_name[0.."source.fish".len], "source.fish");
        @memcpy(gi.file_types[0][0.."fish".len], "fish");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_70[0..grammar_70.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."fluent".len], "fluent");
        @memcpy(gi.scope_name[0.."source.ftl".len], "source.ftl");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_71[0..grammar_71.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 6, .inject_only = false };
        @memcpy(gi.name[0.."fortran-fixed-form".len], "fortran-fixed-form");
        @memcpy(gi.scope_name[0.."source.fortran.fixed".len], "source.fortran.fixed");
        @memcpy(gi.file_types[0][0.."f".len], "f");
        @memcpy(gi.file_types[1][0.."F".len], "F");
        @memcpy(gi.file_types[2][0.."f77".len], "f77");
        @memcpy(gi.file_types[3][0.."F77".len], "F77");
        @memcpy(gi.file_types[4][0.."for".len], "for");
        @memcpy(gi.file_types[5][0.."FOR".len], "FOR");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_72[0..grammar_72.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 8, .inject_only = false };
        @memcpy(gi.name[0.."fortran-free-form".len], "fortran-free-form");
        @memcpy(gi.scope_name[0.."source.fortran.free".len], "source.fortran.free");
        @memcpy(gi.file_types[0][0.."f90".len], "f90");
        @memcpy(gi.file_types[1][0.."F90".len], "F90");
        @memcpy(gi.file_types[2][0.."f95".len], "f95");
        @memcpy(gi.file_types[3][0.."F95".len], "F95");
        @memcpy(gi.file_types[4][0.."f03".len], "f03");
        @memcpy(gi.file_types[5][0.."F03".len], "F03");
        @memcpy(gi.file_types[6][0.."f08".len], "f08");
        @memcpy(gi.file_types[7][0.."F08".len], "F08");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_73[0..grammar_73.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."fsharp".len], "fsharp");
        @memcpy(gi.scope_name[0.."source.fsharp".len], "source.fsharp");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_74[0..grammar_74.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."gdresource".len], "gdresource");
        @memcpy(gi.scope_name[0.."source.gdresource".len], "source.gdresource");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_75[0..grammar_75.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."gdscript".len], "gdscript");
        @memcpy(gi.scope_name[0.."source.gdscript".len], "source.gdscript");
        @memcpy(gi.file_types[0][0.."gd".len], "gd");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_76[0..grammar_76.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."gdshader".len], "gdshader");
        @memcpy(gi.scope_name[0.."source.gdshader".len], "source.gdshader");
        @memcpy(gi.file_types[0][0.."gdshader".len], "gdshader");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_77[0..grammar_77.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."genie".len], "genie");
        @memcpy(gi.scope_name[0.."source.genie".len], "source.genie");
        @memcpy(gi.file_types[0][0.."gs".len], "gs");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_78[0..grammar_78.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."gherkin".len], "gherkin");
        @memcpy(gi.scope_name[0.."text.gherkin.feature".len], "text.gherkin.feature");
        @memcpy(gi.file_types[0][0.."feature".len], "feature");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_79[0..grammar_79.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."git-commit".len], "git-commit");
        @memcpy(gi.scope_name[0.."text.git-commit".len], "text.git-commit");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_80[0..grammar_80.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."git-rebase".len], "git-rebase");
        @memcpy(gi.scope_name[0.."text.git-rebase".len], "text.git-rebase");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_81[0..grammar_81.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."gleam".len], "gleam");
        @memcpy(gi.scope_name[0.."source.gleam".len], "source.gleam");
        @memcpy(gi.file_types[0][0.."gleam".len], "gleam");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_82[0..grammar_82.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."glimmer-js".len], "glimmer-js");
        @memcpy(gi.scope_name[0.."source.gjs".len], "source.gjs");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_83[0..grammar_83.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."glimmer-ts".len], "glimmer-ts");
        @memcpy(gi.scope_name[0.."source.gts".len], "source.gts");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_84[0..grammar_84.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 8, .inject_only = false };
        @memcpy(gi.name[0.."glsl".len], "glsl");
        @memcpy(gi.scope_name[0.."source.glsl".len], "source.glsl");
        @memcpy(gi.file_types[0][0.."vs".len], "vs");
        @memcpy(gi.file_types[1][0.."fs".len], "fs");
        @memcpy(gi.file_types[2][0.."gs".len], "gs");
        @memcpy(gi.file_types[3][0.."vsh".len], "vsh");
        @memcpy(gi.file_types[4][0.."fsh".len], "fsh");
        @memcpy(gi.file_types[5][0.."gsh".len], "gsh");
        @memcpy(gi.file_types[6][0.."vshader".len], "vshader");
        @memcpy(gi.file_types[7][0.."fshader".len], "fshader");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_85[0..grammar_85.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 4, .inject_only = false };
        @memcpy(gi.name[0.."gnuplot".len], "gnuplot");
        @memcpy(gi.scope_name[0.."source.gnuplot".len], "source.gnuplot");
        @memcpy(gi.file_types[0][0.."gp".len], "gp");
        @memcpy(gi.file_types[1][0.."plt".len], "plt");
        @memcpy(gi.file_types[2][0.."plot".len], "plot");
        @memcpy(gi.file_types[3][0.."gnuplot".len], "gnuplot");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_86[0..grammar_86.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."go".len], "go");
        @memcpy(gi.scope_name[0.."source.go".len], "source.go");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_87[0..grammar_87.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 4, .inject_only = false };
        @memcpy(gi.name[0.."graphql".len], "graphql");
        @memcpy(gi.scope_name[0.."source.graphql".len], "source.graphql");
        @memcpy(gi.file_types[0][0.."graphql".len], "graphql");
        @memcpy(gi.file_types[1][0.."graphqls".len], "graphqls");
        @memcpy(gi.file_types[2][0.."gql".len], "gql");
        @memcpy(gi.file_types[3][0.."graphcool".len], "graphcool");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_88[0..grammar_88.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."groovy".len], "groovy");
        @memcpy(gi.scope_name[0.."source.groovy".len], "source.groovy");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_89[0..grammar_89.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 3, .inject_only = false };
        @memcpy(gi.name[0.."hack".len], "hack");
        @memcpy(gi.scope_name[0.."source.hack".len], "source.hack");
        @memcpy(gi.file_types[0][0.."hh".len], "hh");
        @memcpy(gi.file_types[1][0.."php".len], "php");
        @memcpy(gi.file_types[2][0.."hack".len], "hack");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_90[0..grammar_90.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."haml".len], "haml");
        @memcpy(gi.scope_name[0.."text.haml".len], "text.haml");
        @memcpy(gi.file_types[0][0.."haml".len], "haml");
        @memcpy(gi.file_types[1][0.."html.haml".len], "html.haml");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_91[0..grammar_91.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."handlebars".len], "handlebars");
        @memcpy(gi.scope_name[0.."text.html.handlebars".len], "text.html.handlebars");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_92[0..grammar_92.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 3, .inject_only = false };
        @memcpy(gi.name[0.."haskell".len], "haskell");
        @memcpy(gi.scope_name[0.."source.haskell".len], "source.haskell");
        @memcpy(gi.file_types[0][0.."hs".len], "hs");
        @memcpy(gi.file_types[1][0.."hs-boot".len], "hs-boot");
        @memcpy(gi.file_types[2][0.."hsig".len], "hsig");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_93[0..grammar_93.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."haxe".len], "haxe");
        @memcpy(gi.scope_name[0.."source.hx".len], "source.hx");
        @memcpy(gi.file_types[0][0.."hx".len], "hx");
        @memcpy(gi.file_types[1][0.."dump".len], "dump");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_94[0..grammar_94.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."hcl".len], "hcl");
        @memcpy(gi.scope_name[0.."source.hcl".len], "source.hcl");
        @memcpy(gi.file_types[0][0.."hcl".len], "hcl");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_95[0..grammar_95.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."hjson".len], "hjson");
        @memcpy(gi.scope_name[0.."source.hjson".len], "source.hjson");
        @memcpy(gi.file_types[0][0.."hjson".len], "hjson");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_96[0..grammar_96.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."hlsl".len], "hlsl");
        @memcpy(gi.scope_name[0.."source.hlsl".len], "source.hlsl");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_97[0..grammar_97.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."html-derivative".len], "html-derivative");
        @memcpy(gi.scope_name[0.."text.html.derivative".len], "text.html.derivative");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_98[0..grammar_98.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."html".len], "html");
        @memcpy(gi.scope_name[0.."text.html.basic".len], "text.html.basic");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_99[0..grammar_99.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."http".len], "http");
        @memcpy(gi.scope_name[0.."source.http".len], "source.http");
        @memcpy(gi.file_types[0][0.."http".len], "http");
        @memcpy(gi.file_types[1][0.."rest".len], "rest");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_100[0..grammar_100.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."hxml".len], "hxml");
        @memcpy(gi.scope_name[0.."source.hxml".len], "source.hxml");
        @memcpy(gi.file_types[0][0.."hxml".len], "hxml");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_101[0..grammar_101.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."hy".len], "hy");
        @memcpy(gi.scope_name[0.."source.hy".len], "source.hy");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_102[0..grammar_102.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."imba".len], "imba");
        @memcpy(gi.scope_name[0.."source.imba".len], "source.imba");
        @memcpy(gi.file_types[0][0.."imba".len], "imba");
        @memcpy(gi.file_types[1][0.."imba2".len], "imba2");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_103[0..grammar_103.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."ini".len], "ini");
        @memcpy(gi.scope_name[0.."source.ini".len], "source.ini");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_104[0..grammar_104.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."java".len], "java");
        @memcpy(gi.scope_name[0.."source.java".len], "source.java");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_105[0..grammar_105.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."javascript".len], "javascript");
        @memcpy(gi.scope_name[0.."source.js".len], "source.js");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_106[0..grammar_106.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."jinja-html".len], "jinja-html");
        @memcpy(gi.scope_name[0.."text.html.jinja".len], "text.html.jinja");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_107[0..grammar_107.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."jinja".len], "jinja");
        @memcpy(gi.scope_name[0.."source.jinja".len], "source.jinja");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_108[0..grammar_108.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."jison".len], "jison");
        @memcpy(gi.scope_name[0.."source.jison".len], "source.jison");
        @memcpy(gi.file_types[0][0.."jison".len], "jison");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_109[0..grammar_109.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."json".len], "json");
        @memcpy(gi.scope_name[0.."source.json".len], "source.json");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_110[0..grammar_110.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."json5".len], "json5");
        @memcpy(gi.scope_name[0.."source.json5".len], "source.json5");
        @memcpy(gi.file_types[0][0.."json5".len], "json5");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_111[0..grammar_111.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."jsonc".len], "jsonc");
        @memcpy(gi.scope_name[0.."source.json.comments".len], "source.json.comments");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_112[0..grammar_112.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."jsonl".len], "jsonl");
        @memcpy(gi.scope_name[0.."source.json.lines".len], "source.json.lines");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_113[0..grammar_113.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."jsonnet".len], "jsonnet");
        @memcpy(gi.scope_name[0.."source.jsonnet".len], "source.jsonnet");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_114[0..grammar_114.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."jssm".len], "jssm");
        @memcpy(gi.scope_name[0.."source.jssm".len], "source.jssm");
        @memcpy(gi.file_types[0][0.."jssm".len], "jssm");
        @memcpy(gi.file_types[1][0.."jssm_state".len], "jssm_state");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_115[0..grammar_115.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."jsx".len], "jsx");
        @memcpy(gi.scope_name[0.."source.js.jsx".len], "source.js.jsx");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_116[0..grammar_116.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."julia".len], "julia");
        @memcpy(gi.scope_name[0.."source.julia".len], "source.julia");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_117[0..grammar_117.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."kotlin".len], "kotlin");
        @memcpy(gi.scope_name[0.."source.kotlin".len], "source.kotlin");
        @memcpy(gi.file_types[0][0.."kt".len], "kt");
        @memcpy(gi.file_types[1][0.."kts".len], "kts");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_118[0..grammar_118.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 3, .inject_only = false };
        @memcpy(gi.name[0.."kusto".len], "kusto");
        @memcpy(gi.scope_name[0.."source.kusto".len], "source.kusto");
        @memcpy(gi.file_types[0][0.."csl".len], "csl");
        @memcpy(gi.file_types[1][0.."kusto".len], "kusto");
        @memcpy(gi.file_types[2][0.."kql".len], "kql");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_119[0..grammar_119.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."latex".len], "latex");
        @memcpy(gi.scope_name[0.."text.tex.latex".len], "text.tex.latex");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_120[0..grammar_120.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."lean".len], "lean");
        @memcpy(gi.scope_name[0.."source.lean4".len], "source.lean4");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_121[0..grammar_121.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."less".len], "less");
        @memcpy(gi.scope_name[0.."source.css.less".len], "source.css.less");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_122[0..grammar_122.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."liquid".len], "liquid");
        @memcpy(gi.scope_name[0.."text.html.liquid".len], "text.html.liquid");
        @memcpy(gi.file_types[0][0.."liquid".len], "liquid");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_123[0..grammar_123.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."llvm".len], "llvm");
        @memcpy(gi.scope_name[0.."source.llvm".len], "source.llvm");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_124[0..grammar_124.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."log".len], "log");
        @memcpy(gi.scope_name[0.."text.log".len], "text.log");
        @memcpy(gi.file_types[0][0.."log".len], "log");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_125[0..grammar_125.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."logo".len], "logo");
        @memcpy(gi.scope_name[0.."source.logo".len], "source.logo");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_126[0..grammar_126.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."lua".len], "lua");
        @memcpy(gi.scope_name[0.."source.lua".len], "source.lua");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_127[0..grammar_127.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."luau".len], "luau");
        @memcpy(gi.scope_name[0.."source.luau".len], "source.luau");
        @memcpy(gi.file_types[0][0.."luau".len], "luau");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_128[0..grammar_128.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."make".len], "make");
        @memcpy(gi.scope_name[0.."source.makefile".len], "source.makefile");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_129[0..grammar_129.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = true };
        @memcpy(gi.name[0.."markdown-vue".len], "markdown-vue");
        @memcpy(gi.scope_name[0.."markdown.vue.codeblock".len], "markdown.vue.codeblock");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_130[0..grammar_130.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."markdown".len], "markdown");
        @memcpy(gi.scope_name[0.."text.html.markdown".len], "text.html.markdown");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_131[0..grammar_131.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."marko".len], "marko");
        @memcpy(gi.scope_name[0.."text.marko".len], "text.marko");
        @memcpy(gi.file_types[0][0.."marko".len], "marko");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_132[0..grammar_132.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."matlab".len], "matlab");
        @memcpy(gi.scope_name[0.."source.matlab".len], "source.matlab");
        @memcpy(gi.file_types[0][0.."m".len], "m");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_133[0..grammar_133.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."mdc".len], "mdc");
        @memcpy(gi.scope_name[0.."text.markdown.mdc.standalone".len], "text.markdown.mdc.standalone");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_134[0..grammar_134.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."mdx".len], "mdx");
        @memcpy(gi.scope_name[0.."source.mdx".len], "source.mdx");
        @memcpy(gi.file_types[0][0.."mdx".len], "mdx");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_135[0..grammar_135.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."mermaid".len], "mermaid");
        @memcpy(gi.scope_name[0.."markdown.mermaid.codeblock".len], "markdown.mermaid.codeblock");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_136[0..grammar_136.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 4, .inject_only = false };
        @memcpy(gi.name[0.."mipsasm".len], "mipsasm");
        @memcpy(gi.scope_name[0.."source.mips".len], "source.mips");
        @memcpy(gi.file_types[0][0.."s".len], "s");
        @memcpy(gi.file_types[1][0.."mips".len], "mips");
        @memcpy(gi.file_types[2][0.."spim".len], "spim");
        @memcpy(gi.file_types[3][0.."asm".len], "asm");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_137[0..grammar_137.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."mojo".len], "mojo");
        @memcpy(gi.scope_name[0.."source.mojo".len], "source.mojo");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_138[0..grammar_138.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."move".len], "move");
        @memcpy(gi.scope_name[0.."source.move".len], "source.move");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_139[0..grammar_139.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."narrat".len], "narrat");
        @memcpy(gi.scope_name[0.."source.narrat".len], "source.narrat");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_140[0..grammar_140.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."nextflow".len], "nextflow");
        @memcpy(gi.scope_name[0.."source.nextflow".len], "source.nextflow");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_141[0..grammar_141.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 8, .inject_only = false };
        @memcpy(gi.name[0.."nginx".len], "nginx");
        @memcpy(gi.scope_name[0.."source.nginx".len], "source.nginx");
        @memcpy(gi.file_types[0][0.."conf.erb".len], "conf.erb");
        @memcpy(gi.file_types[1][0.."conf".len], "conf");
        @memcpy(gi.file_types[2][0.."ngx".len], "ngx");
        @memcpy(gi.file_types[3][0.."nginx.conf".len], "nginx.conf");
        @memcpy(gi.file_types[4][0.."mime.types".len], "mime.types");
        @memcpy(gi.file_types[5][0.."fastcgi_params".len], "fastcgi_params");
        @memcpy(gi.file_types[6][0.."scgi_params".len], "scgi_params");
        @memcpy(gi.file_types[7][0.."uwsgi_params".len], "uwsgi_params");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_142[0..grammar_142.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."nim".len], "nim");
        @memcpy(gi.scope_name[0.."source.nim".len], "source.nim");
        @memcpy(gi.file_types[0][0.."nim".len], "nim");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_143[0..grammar_143.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."nix".len], "nix");
        @memcpy(gi.scope_name[0.."source.nix".len], "source.nix");
        @memcpy(gi.file_types[0][0.."nix".len], "nix");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_144[0..grammar_144.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."nushell".len], "nushell");
        @memcpy(gi.scope_name[0.."source.nushell".len], "source.nushell");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_145[0..grammar_145.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."objective-c".len], "objective-c");
        @memcpy(gi.scope_name[0.."source.objc".len], "source.objc");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_146[0..grammar_146.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."objective-cpp".len], "objective-cpp");
        @memcpy(gi.scope_name[0.."source.objcpp".len], "source.objcpp");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_147[0..grammar_147.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."ocaml".len], "ocaml");
        @memcpy(gi.scope_name[0.."source.ocaml".len], "source.ocaml");
        @memcpy(gi.file_types[0][0..".ml".len], ".ml");
        @memcpy(gi.file_types[1][0..".mli".len], ".mli");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_148[0..grammar_148.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 8, .inject_only = false };
        @memcpy(gi.name[0.."pascal".len], "pascal");
        @memcpy(gi.scope_name[0.."source.pascal".len], "source.pascal");
        @memcpy(gi.file_types[0][0.."pas".len], "pas");
        @memcpy(gi.file_types[1][0.."p".len], "p");
        @memcpy(gi.file_types[2][0.."pp".len], "pp");
        @memcpy(gi.file_types[3][0.."dfm".len], "dfm");
        @memcpy(gi.file_types[4][0.."fmx".len], "fmx");
        @memcpy(gi.file_types[5][0.."dpr".len], "dpr");
        @memcpy(gi.file_types[6][0.."dpk".len], "dpk");
        @memcpy(gi.file_types[7][0.."lfm".len], "lfm");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_149[0..grammar_149.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."perl".len], "perl");
        @memcpy(gi.scope_name[0.."source.perl".len], "source.perl");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_150[0..grammar_150.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."php".len], "php");
        @memcpy(gi.scope_name[0.."source.php".len], "source.php");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_151[0..grammar_151.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 8, .inject_only = false };
        @memcpy(gi.name[0.."plsql".len], "plsql");
        @memcpy(gi.scope_name[0.."source.plsql.oracle".len], "source.plsql.oracle");
        @memcpy(gi.file_types[0][0.."sql".len], "sql");
        @memcpy(gi.file_types[1][0.."ddl".len], "ddl");
        @memcpy(gi.file_types[2][0.."dml".len], "dml");
        @memcpy(gi.file_types[3][0.."pkh".len], "pkh");
        @memcpy(gi.file_types[4][0.."pks".len], "pks");
        @memcpy(gi.file_types[5][0.."pkb".len], "pkb");
        @memcpy(gi.file_types[6][0.."pck".len], "pck");
        @memcpy(gi.file_types[7][0.."pls".len], "pls");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_152[0..grammar_152.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 3, .inject_only = false };
        @memcpy(gi.name[0.."po".len], "po");
        @memcpy(gi.scope_name[0.."source.po".len], "source.po");
        @memcpy(gi.file_types[0][0.."po".len], "po");
        @memcpy(gi.file_types[1][0.."pot".len], "pot");
        @memcpy(gi.file_types[2][0.."potx".len], "potx");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_153[0..grammar_153.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."polar".len], "polar");
        @memcpy(gi.scope_name[0.."source.polar".len], "source.polar");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_154[0..grammar_154.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."postcss".len], "postcss");
        @memcpy(gi.scope_name[0.."source.css.postcss".len], "source.css.postcss");
        @memcpy(gi.file_types[0][0.."pcss".len], "pcss");
        @memcpy(gi.file_types[1][0.."postcss".len], "postcss");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_155[0..grammar_155.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."powerquery".len], "powerquery");
        @memcpy(gi.scope_name[0.."source.powerquery".len], "source.powerquery");
        @memcpy(gi.file_types[0][0.."pq".len], "pq");
        @memcpy(gi.file_types[1][0.."pqm".len], "pqm");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_156[0..grammar_156.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."powershell".len], "powershell");
        @memcpy(gi.scope_name[0.."source.powershell".len], "source.powershell");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_157[0..grammar_157.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."prisma".len], "prisma");
        @memcpy(gi.scope_name[0.."source.prisma".len], "source.prisma");
        @memcpy(gi.file_types[0][0.."prisma".len], "prisma");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_158[0..grammar_158.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."prolog".len], "prolog");
        @memcpy(gi.scope_name[0.."source.prolog".len], "source.prolog");
        @memcpy(gi.file_types[0][0.."pl".len], "pl");
        @memcpy(gi.file_types[1][0.."pro".len], "pro");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_159[0..grammar_159.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."proto".len], "proto");
        @memcpy(gi.scope_name[0.."source.proto".len], "source.proto");
        @memcpy(gi.file_types[0][0.."proto".len], "proto");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_160[0..grammar_160.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."pug".len], "pug");
        @memcpy(gi.scope_name[0.."text.pug".len], "text.pug");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_161[0..grammar_161.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."puppet".len], "puppet");
        @memcpy(gi.scope_name[0.."source.puppet".len], "source.puppet");
        @memcpy(gi.file_types[0][0.."pp".len], "pp");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_162[0..grammar_162.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."purescript".len], "purescript");
        @memcpy(gi.scope_name[0.."source.purescript".len], "source.purescript");
        @memcpy(gi.file_types[0][0.."purs".len], "purs");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_163[0..grammar_163.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."python".len], "python");
        @memcpy(gi.scope_name[0.."source.python".len], "source.python");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_164[0..grammar_164.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."qml".len], "qml");
        @memcpy(gi.scope_name[0.."source.qml".len], "source.qml");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_165[0..grammar_165.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."qmldir".len], "qmldir");
        @memcpy(gi.scope_name[0.."source.qmldir".len], "source.qmldir");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_166[0..grammar_166.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."qss".len], "qss");
        @memcpy(gi.scope_name[0.."source.qss".len], "source.qss");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_167[0..grammar_167.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."r".len], "r");
        @memcpy(gi.scope_name[0.."source.r".len], "source.r");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_168[0..grammar_168.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."racket".len], "racket");
        @memcpy(gi.scope_name[0.."source.racket".len], "source.racket");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_169[0..grammar_169.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."raku".len], "raku");
        @memcpy(gi.scope_name[0.."source.perl.6".len], "source.perl.6");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_170[0..grammar_170.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."razor".len], "razor");
        @memcpy(gi.scope_name[0.."text.aspnetcorerazor".len], "text.aspnetcorerazor");
        @memcpy(gi.file_types[0][0.."razor".len], "razor");
        @memcpy(gi.file_types[1][0.."cshtml".len], "cshtml");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_171[0..grammar_171.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."reg".len], "reg");
        @memcpy(gi.scope_name[0.."source.reg".len], "source.reg");
        @memcpy(gi.file_types[0][0.."reg".len], "reg");
        @memcpy(gi.file_types[1][0.."REG".len], "REG");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_172[0..grammar_172.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."regexp".len], "regexp");
        @memcpy(gi.scope_name[0.."source.regexp.python".len], "source.regexp.python");
        @memcpy(gi.file_types[0][0.."re".len], "re");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_173[0..grammar_173.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."rel".len], "rel");
        @memcpy(gi.scope_name[0.."source.rel".len], "source.rel");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_174[0..grammar_174.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 4, .inject_only = false };
        @memcpy(gi.name[0.."riscv".len], "riscv");
        @memcpy(gi.scope_name[0.."source.riscv".len], "source.riscv");
        @memcpy(gi.file_types[0][0.."S".len], "S");
        @memcpy(gi.file_types[1][0.."s".len], "s");
        @memcpy(gi.file_types[2][0.."riscv".len], "riscv");
        @memcpy(gi.file_types[3][0.."asm".len], "asm");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_175[0..grammar_175.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."rst".len], "rst");
        @memcpy(gi.scope_name[0.."source.rst".len], "source.rst");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_176[0..grammar_176.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."ruby".len], "ruby");
        @memcpy(gi.scope_name[0.."source.ruby".len], "source.ruby");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_177[0..grammar_177.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."rust".len], "rust");
        @memcpy(gi.scope_name[0.."source.rust".len], "source.rust");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_178[0..grammar_178.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."sas".len], "sas");
        @memcpy(gi.scope_name[0.."source.sas".len], "source.sas");
        @memcpy(gi.file_types[0][0.."sas".len], "sas");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_179[0..grammar_179.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."sass".len], "sass");
        @memcpy(gi.scope_name[0.."source.sass".len], "source.sass");
        @memcpy(gi.file_types[0][0.."sass".len], "sass");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_180[0..grammar_180.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."scala".len], "scala");
        @memcpy(gi.scope_name[0.."source.scala".len], "source.scala");
        @memcpy(gi.file_types[0][0.."scala".len], "scala");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_181[0..grammar_181.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 4, .inject_only = false };
        @memcpy(gi.name[0.."scheme".len], "scheme");
        @memcpy(gi.scope_name[0.."source.scheme".len], "source.scheme");
        @memcpy(gi.file_types[0][0.."scm".len], "scm");
        @memcpy(gi.file_types[1][0.."ss".len], "ss");
        @memcpy(gi.file_types[2][0.."sch".len], "sch");
        @memcpy(gi.file_types[3][0.."rkt".len], "rkt");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_182[0..grammar_182.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."scss".len], "scss");
        @memcpy(gi.scope_name[0.."source.css.scss".len], "source.css.scss");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_183[0..grammar_183.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."sdbl".len], "sdbl");
        @memcpy(gi.scope_name[0.."source.sdbl".len], "source.sdbl");
        @memcpy(gi.file_types[0][0.."sdbl".len], "sdbl");
        @memcpy(gi.file_types[1][0.."query".len], "query");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_184[0..grammar_184.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."shaderlab".len], "shaderlab");
        @memcpy(gi.scope_name[0.."source.shaderlab".len], "source.shaderlab");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_185[0..grammar_185.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."shellscript".len], "shellscript");
        @memcpy(gi.scope_name[0.."source.shell".len], "source.shell");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_186[0..grammar_186.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."shellsession".len], "shellsession");
        @memcpy(gi.scope_name[0.."text.shell-session".len], "text.shell-session");
        @memcpy(gi.file_types[0][0.."sh-session".len], "sh-session");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_187[0..grammar_187.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."smalltalk".len], "smalltalk");
        @memcpy(gi.scope_name[0.."source.smalltalk".len], "source.smalltalk");
        @memcpy(gi.file_types[0][0.."st".len], "st");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_188[0..grammar_188.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."solidity".len], "solidity");
        @memcpy(gi.scope_name[0.."source.solidity".len], "source.solidity");
        @memcpy(gi.file_types[0][0.."sol".len], "sol");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_189[0..grammar_189.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."soy".len], "soy");
        @memcpy(gi.scope_name[0.."text.html.soy".len], "text.html.soy");
        @memcpy(gi.file_types[0][0.."soy".len], "soy");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_190[0..grammar_190.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 3, .inject_only = false };
        @memcpy(gi.name[0.."sparql".len], "sparql");
        @memcpy(gi.scope_name[0.."source.sparql".len], "source.sparql");
        @memcpy(gi.file_types[0][0.."rq".len], "rq");
        @memcpy(gi.file_types[1][0.."sparql".len], "sparql");
        @memcpy(gi.file_types[2][0.."sq".len], "sq");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_191[0..grammar_191.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."splunk".len], "splunk");
        @memcpy(gi.scope_name[0.."source.splunk_search".len], "source.splunk_search");
        @memcpy(gi.file_types[0][0.."splunk".len], "splunk");
        @memcpy(gi.file_types[1][0.."spl".len], "spl");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_192[0..grammar_192.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."sql".len], "sql");
        @memcpy(gi.scope_name[0.."source.sql".len], "source.sql");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_193[0..grammar_193.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 3, .inject_only = false };
        @memcpy(gi.name[0.."ssh-config".len], "ssh-config");
        @memcpy(gi.scope_name[0.."source.ssh-config".len], "source.ssh-config");
        @memcpy(gi.file_types[0][0.."ssh_config".len], "ssh_config");
        @memcpy(gi.file_types[1][0..".ssh/config".len], ".ssh/config");
        @memcpy(gi.file_types[2][0.."sshd_config".len], "sshd_config");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_194[0..grammar_194.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 3, .inject_only = false };
        @memcpy(gi.name[0.."stata".len], "stata");
        @memcpy(gi.scope_name[0.."source.stata".len], "source.stata");
        @memcpy(gi.file_types[0][0.."do".len], "do");
        @memcpy(gi.file_types[1][0.."ado".len], "ado");
        @memcpy(gi.file_types[2][0.."mata".len], "mata");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_195[0..grammar_195.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 4, .inject_only = false };
        @memcpy(gi.name[0.."stylus".len], "stylus");
        @memcpy(gi.scope_name[0.."source.stylus".len], "source.stylus");
        @memcpy(gi.file_types[0][0.."styl".len], "styl");
        @memcpy(gi.file_types[1][0.."stylus".len], "stylus");
        @memcpy(gi.file_types[2][0.."css.styl".len], "css.styl");
        @memcpy(gi.file_types[3][0.."css.stylus".len], "css.stylus");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_196[0..grammar_196.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."svelte".len], "svelte");
        @memcpy(gi.scope_name[0.."source.svelte".len], "source.svelte");
        @memcpy(gi.file_types[0][0.."svelte".len], "svelte");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_197[0..grammar_197.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."swift".len], "swift");
        @memcpy(gi.scope_name[0.."source.swift".len], "source.swift");
        @memcpy(gi.file_types[0][0.."swift".len], "swift");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_198[0..grammar_198.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 4, .inject_only = false };
        @memcpy(gi.name[0.."system-verilog".len], "system-verilog");
        @memcpy(gi.scope_name[0.."source.systemverilog".len], "source.systemverilog");
        @memcpy(gi.file_types[0][0.."v".len], "v");
        @memcpy(gi.file_types[1][0.."vh".len], "vh");
        @memcpy(gi.file_types[2][0.."sv".len], "sv");
        @memcpy(gi.file_types[3][0.."svh".len], "svh");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_199[0..grammar_199.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."systemd".len], "systemd");
        @memcpy(gi.scope_name[0.."source.systemd".len], "source.systemd");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_200[0..grammar_200.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."talonscript".len], "talonscript");
        @memcpy(gi.scope_name[0.."source.talon".len], "source.talon");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_201[0..grammar_201.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."tasl".len], "tasl");
        @memcpy(gi.scope_name[0.."source.tasl".len], "source.tasl");
        @memcpy(gi.file_types[0][0.."tasl".len], "tasl");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_202[0..grammar_202.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."tcl".len], "tcl");
        @memcpy(gi.scope_name[0.."source.tcl".len], "source.tcl");
        @memcpy(gi.file_types[0][0.."tcl".len], "tcl");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_203[0..grammar_203.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."templ".len], "templ");
        @memcpy(gi.scope_name[0.."source.templ".len], "source.templ");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_204[0..grammar_204.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."terraform".len], "terraform");
        @memcpy(gi.scope_name[0.."source.hcl.terraform".len], "source.hcl.terraform");
        @memcpy(gi.file_types[0][0.."tf".len], "tf");
        @memcpy(gi.file_types[1][0.."tfvars".len], "tfvars");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_205[0..grammar_205.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."tex".len], "tex");
        @memcpy(gi.scope_name[0.."text.tex".len], "text.tex");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_206[0..grammar_206.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."toml".len], "toml");
        @memcpy(gi.scope_name[0.."source.toml".len], "source.toml");
        @memcpy(gi.file_types[0][0.."toml".len], "toml");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_207[0..grammar_207.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."ts-tags".len], "ts-tags");
        @memcpy(gi.scope_name[0.."source.ts.tags".len], "source.ts.tags");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_208[0..grammar_208.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."tsv".len], "tsv");
        @memcpy(gi.scope_name[0.."text.tsv".len], "text.tsv");
        @memcpy(gi.file_types[0][0.."tsv".len], "tsv");
        @memcpy(gi.file_types[1][0.."tab".len], "tab");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_209[0..grammar_209.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."tsx".len], "tsx");
        @memcpy(gi.scope_name[0.."source.tsx".len], "source.tsx");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_210[0..grammar_210.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 3, .inject_only = false };
        @memcpy(gi.name[0.."turtle".len], "turtle");
        @memcpy(gi.scope_name[0.."source.turtle".len], "source.turtle");
        @memcpy(gi.file_types[0][0.."turtle".len], "turtle");
        @memcpy(gi.file_types[1][0.."ttl".len], "ttl");
        @memcpy(gi.file_types[2][0.."acl".len], "acl");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_211[0..grammar_211.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."twig".len], "twig");
        @memcpy(gi.scope_name[0.."text.html.twig".len], "text.html.twig");
        @memcpy(gi.file_types[0][0.."twig".len], "twig");
        @memcpy(gi.file_types[1][0.."html.twig".len], "html.twig");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_212[0..grammar_212.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."typescript".len], "typescript");
        @memcpy(gi.scope_name[0.."source.ts".len], "source.ts");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_213[0..grammar_213.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."typespec".len], "typespec");
        @memcpy(gi.scope_name[0.."source.tsp".len], "source.tsp");
        @memcpy(gi.file_types[0][0.."tsp".len], "tsp");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_214[0..grammar_214.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."typst".len], "typst");
        @memcpy(gi.scope_name[0.."source.typst".len], "source.typst");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_215[0..grammar_215.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 5, .inject_only = false };
        @memcpy(gi.name[0.."v".len], "v");
        @memcpy(gi.scope_name[0.."source.v".len], "source.v");
        @memcpy(gi.file_types[0][0..".v".len], ".v");
        @memcpy(gi.file_types[1][0..".vh".len], ".vh");
        @memcpy(gi.file_types[2][0..".vsh".len], ".vsh");
        @memcpy(gi.file_types[3][0..".vv".len], ".vv");
        @memcpy(gi.file_types[4][0.."v.mod".len], "v.mod");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_216[0..grammar_216.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 3, .inject_only = false };
        @memcpy(gi.name[0.."vala".len], "vala");
        @memcpy(gi.scope_name[0.."source.vala".len], "source.vala");
        @memcpy(gi.file_types[0][0.."vala".len], "vala");
        @memcpy(gi.file_types[1][0.."vapi".len], "vapi");
        @memcpy(gi.file_types[2][0.."gs".len], "gs");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_217[0..grammar_217.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."vb".len], "vb");
        @memcpy(gi.scope_name[0.."source.asp.vb.net".len], "source.asp.vb.net");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_218[0..grammar_218.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."verilog".len], "verilog");
        @memcpy(gi.scope_name[0.."source.verilog".len], "source.verilog");
        @memcpy(gi.file_types[0][0.."v".len], "v");
        @memcpy(gi.file_types[1][0.."vh".len], "vh");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_219[0..grammar_219.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 4, .inject_only = false };
        @memcpy(gi.name[0.."vhdl".len], "vhdl");
        @memcpy(gi.scope_name[0.."source.vhdl".len], "source.vhdl");
        @memcpy(gi.file_types[0][0.."vhd".len], "vhd");
        @memcpy(gi.file_types[1][0.."vhdl".len], "vhdl");
        @memcpy(gi.file_types[2][0.."vho".len], "vho");
        @memcpy(gi.file_types[3][0.."vht".len], "vht");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_220[0..grammar_220.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."viml".len], "viml");
        @memcpy(gi.scope_name[0.."source.viml".len], "source.viml");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_221[0..grammar_221.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = true };
        @memcpy(gi.name[0.."vue-directives".len], "vue-directives");
        @memcpy(gi.scope_name[0.."vue.directives".len], "vue.directives");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_222[0..grammar_222.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."vue-html".len], "vue-html");
        @memcpy(gi.scope_name[0.."text.html.vue-html".len], "text.html.vue-html");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_223[0..grammar_223.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = true };
        @memcpy(gi.name[0.."vue-interpolations".len], "vue-interpolations");
        @memcpy(gi.scope_name[0.."vue.interpolations".len], "vue.interpolations");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_224[0..grammar_224.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = true };
        @memcpy(gi.name[0.."vue-sfc-style-variable-injection".len], "vue-sfc-style-variable-injection");
        @memcpy(gi.scope_name[0.."vue.sfc.style.variable.injection".len], "vue.sfc.style.variable.injection");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_225[0..grammar_225.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."vue-vine".len], "vue-vine");
        @memcpy(gi.scope_name[0.."source.vue-vine".len], "source.vue-vine");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_226[0..grammar_226.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."vue".len], "vue");
        @memcpy(gi.scope_name[0.."source.vue".len], "source.vue");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_227[0..grammar_227.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."vyper".len], "vyper");
        @memcpy(gi.scope_name[0.."source.vyper".len], "source.vyper");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_228[0..grammar_228.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."wasm".len], "wasm");
        @memcpy(gi.scope_name[0.."source.wat".len], "source.wat");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_229[0..grammar_229.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."wenyan".len], "wenyan");
        @memcpy(gi.scope_name[0.."source.wenyan".len], "source.wenyan");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_230[0..grammar_230.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."wgsl".len], "wgsl");
        @memcpy(gi.scope_name[0.."source.wgsl".len], "source.wgsl");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_231[0..grammar_231.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."wikitext".len], "wikitext");
        @memcpy(gi.scope_name[0.."source.wikitext".len], "source.wikitext");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_232[0..grammar_232.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."wit".len], "wit");
        @memcpy(gi.scope_name[0.."source.wit".len], "source.wit");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_233[0..grammar_233.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 5, .inject_only = false };
        @memcpy(gi.name[0.."wolfram".len], "wolfram");
        @memcpy(gi.scope_name[0.."source.wolfram".len], "source.wolfram");
        @memcpy(gi.file_types[0][0.."wl".len], "wl");
        @memcpy(gi.file_types[1][0.."m".len], "m");
        @memcpy(gi.file_types[2][0.."wls".len], "wls");
        @memcpy(gi.file_types[3][0.."wlt".len], "wlt");
        @memcpy(gi.file_types[4][0.."mt".len], "mt");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_234[0..grammar_234.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."xml".len], "xml");
        @memcpy(gi.scope_name[0.."text.xml".len], "text.xml");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_235[0..grammar_235.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 0, .inject_only = false };
        @memcpy(gi.name[0.."xsl".len], "xsl");
        @memcpy(gi.scope_name[0.."text.xml.xsl".len], "text.xml.xsl");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_236[0..grammar_236.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 8, .inject_only = false };
        @memcpy(gi.name[0.."yaml".len], "yaml");
        @memcpy(gi.scope_name[0.."source.yaml".len], "source.yaml");
        @memcpy(gi.file_types[0][0.."yaml".len], "yaml");
        @memcpy(gi.file_types[1][0.."yml".len], "yml");
        @memcpy(gi.file_types[2][0.."rviz".len], "rviz");
        @memcpy(gi.file_types[3][0.."reek".len], "reek");
        @memcpy(gi.file_types[4][0.."clang-format".len], "clang-format");
        @memcpy(gi.file_types[5][0.."yaml-tmlanguage".len], "yaml-tmlanguage");
        @memcpy(gi.file_types[6][0.."syntax".len], "syntax");
        @memcpy(gi.file_types[7][0.."sublime-syntax".len], "sublime-syntax");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_237[0..grammar_237.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 1, .inject_only = false };
        @memcpy(gi.name[0.."zenscript".len], "zenscript");
        @memcpy(gi.scope_name[0.."source.zenscript".len], "source.zenscript");
        @memcpy(gi.file_types[0][0.."zs".len], "zs");
        try list.append(allocator, gi);
    }
    {
        const bytes: []const u8 = grammar_238[0..grammar_238.len];
        var gi = GrammarInfo{ .embedded_file = bytes, .file_types_count = 2, .inject_only = false };
        @memcpy(gi.name[0.."zig".len], "zig");
        @memcpy(gi.scope_name[0.."source.zig".len], "source.zig");
        @memcpy(gi.file_types[0][0.."zig".len], "zig");
        @memcpy(gi.file_types[1][0.."zon".len], "zon");
        try list.append(allocator, gi);
    }
}
