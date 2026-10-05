package cjvs.env

import std.unittest.*
import std.unittest.testmacro.*

// renderEnvScript 的对外契约：
// - appendLdLibraryPath = false 时不得有自动导出 LD_LIBRARY_PATH 的语句
// - cjenv 函数是显式调用才生效的补充手段，不受该开关影响（其语句带缩进，位于函数体内）
@Test
class EnvRenderTest {
    // 判断脚本中是否存在某个「顶层（不缩进）」语句，避免误判 cjenv 函数体
    func hasTopLevelPrefix(script: String, prefix: String): Bool {
        for (line in script.split("\n")) {
            if (line.startsWith(prefix)) {
                return true
            }
        }
        return false
    }

    @TestCase
    func testBashExportsLdLibraryPathByDefault(): Unit {
        let script = renderEnvScript("bash", "/tmp/cjvs_multishells/1_1", "", true, "linux")
        @Expect(hasTopLevelPrefix(script, "export LD_LIBRARY_PATH="))
    }

    @TestCase
    func testBashNoLdLibraryPathSkipsExport(): Unit {
        let script = renderEnvScript("bash", "/tmp/cjvs_multishells/1_1", "", false, "linux")
        @Expect(!hasTopLevelPrefix(script, "export LD_LIBRARY_PATH="))
        // 仍保留手动调用的 cjenv 函数
        @Expect(script.contains("function cjenv()"))
        @Expect(hasTopLevelPrefix(script, "export CANGJIE_HOME="))
    }

    @TestCase
    func testZshNoLdLibraryPathSkipsExport(): Unit {
        let script = renderEnvScript("zsh", "/tmp/cjvs_multishells/1_1", "", false, "linux")
        @Expect(!hasTopLevelPrefix(script, "export LD_LIBRARY_PATH="))
        @Expect(script.contains("function cjenv()"))
    }

    @TestCase
    func testFishNoLdLibraryPathSkipsExport(): Unit {
        let script = renderEnvScript("fish", "/tmp/cjvs_multishells/1_1", "", false, "linux")
        @Expect(!hasTopLevelPrefix(script, "set -x LD_LIBRARY_PATH"))
        @Expect(hasTopLevelPrefix(script, "set -x CANGJIE_HOME"))
        @Expect(script.contains("function cjenv"))
    }

    @TestCase
    func testElvishNoLdLibraryPathSkipsExport(): Unit {
        let script = renderEnvScript("elvish", "/tmp/cjvs_multishells/1_1", "", false, "linux")
        @Expect(!hasTopLevelPrefix(script, "set-env LD_LIBRARY_PATH"))
        @Expect(hasTopLevelPrefix(script, "set-env CANGJIE_HOME"))
    }

    @TestCase
    func testNushellNoLdLibraryPathSkipsExport(): Unit {
        let script = renderEnvScript("nushell", "/tmp/cjvs_multishells/1_1", "", false, "linux")
        // nushell 渲染没有 cjenv 函数，任何位置都不应出现 LD_LIBRARY_PATH
        @Expect(!script.contains("LD_LIBRARY_PATH"))
    }

    @TestCase
    func testUnknownShell(): Unit {
        @Expect("unsupport shell", renderEnvScript("powershell2", "/tmp/x", "", true, "linux"))
    }

    @TestCase
    func testStdxPathRenderedPerShell(): Unit {
        @Expect("export CANGJIE_STDX_PATH=\"/tmp/stdx\"", renderStdxEnv("bash", "/tmp/stdx"))
        @Expect("set -x CANGJIE_STDX_PATH /tmp/stdx", renderStdxEnv("fish", "/tmp/stdx"))
        @Expect("\$env.CANGJIE_STDX_PATH = '/tmp/stdx'", renderStdxEnv("nushell", "/tmp/stdx"))
    }
}
