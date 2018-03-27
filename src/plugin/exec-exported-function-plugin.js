var ConcatSource = require("webpack-sources/lib/ConcatSource");

function ExecExportedFunctionPlugin() {
    this.banner =
        "#!/usr/bin/env osascript -l JavaScript\n" +
        "ObjC.import(\"stdlib\");\n" +
        "ObjC.import(\"AppKit\");\n" +
        "global = this;\n";
    this.footer =
        "function run(args) { return this.main(args); }";
        // rely on the run arg being overwritten when the script is imported using 'require'.
}

ExecExportedFunctionPlugin.prototype.apply = function(compiler) {
    var banner = this.banner;
    var footer = this.footer;
    compiler.plugin("compilation", function(compilation) {
        compilation.plugin("optimize-chunk-assets", function(chunks, callback) {
            chunks.forEach(function(chunk) {
                chunk.files.forEach(function(file, i) {
                    compilation.assets[file] = new ConcatSource(banner, "\n\n", compilation.assets[file], "\n\n", footer);
                });
            });
            callback();
        });
    });
};

module.exports = ExecExportedFunctionPlugin;