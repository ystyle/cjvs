package cjvs.stdx

import std.fs.{Directory, Path, removeIfExists}
import std.unittest.*
import std.unittest.testmacro.*

// stdx 落盘结构探测的契约：
// - 新结构 <version>/<os>_<arch>_cjnative/<libType>/stdx 与旧结构 <version>/<os>_<arch>_llvm/<libType>/stdx 都要能识别
// - 只有存在 <libType>/stdx 才算该库类型可用（`cjvs stdx ls` 用它打印 (dynamic, static)）
@Test
class StdxLayoutTest {
    let testRoot: Path = Path("/tmp").join("cjvs_stdx_layout_test")

    func makeVersionDir(name: String): Path {
        let versionDir = testRoot.join(name)
        removeIfExists(versionDir, recursive: true)
        Directory.create(versionDir, recursive: true)
        return versionDir
    }

    func cleanup(): Unit {
        removeIfExists(testRoot, recursive: true)
    }

    @TestCase
    func testDetectLibTypeInCjnativeLayout(): Unit {
        let versionDir = makeVersionDir("cjnative")
        Directory.create(versionDir.join("linux_x86_64_cjnative").join("static").join("stdx"), recursive: true)
        @Expect(hasStdxLibType(versionDir, "static"))
        @Expect(!hasStdxLibType(versionDir, "dynamic"))
        cleanup()
    }

    @TestCase
    func testDetectLibTypeInLlvmLayout(): Unit {
        let versionDir = makeVersionDir("llvm")
        Directory.create(versionDir.join("linux_x86_64_llvm").join("dynamic").join("stdx"), recursive: true)
        @Expect(hasStdxLibType(versionDir, "dynamic"))
        @Expect(!hasStdxLibType(versionDir, "static"))
        cleanup()
    }

    @TestCase
    func testDetectBothLibTypes(): Unit {
        let versionDir = makeVersionDir("both")
        Directory.create(versionDir.join("linux_x86_64_cjnative").join("static").join("stdx"), recursive: true)
        Directory.create(versionDir.join("linux_x86_64_cjnative").join("dynamic").join("stdx"), recursive: true)
        @Expect(hasStdxLibType(versionDir, "static"))
        @Expect(hasStdxLibType(versionDir, "dynamic"))
        cleanup()
    }

    @TestCase
    func testLegacyFlatLayout(): Unit {
        let versionDir = makeVersionDir("flat")
        Directory.create(versionDir.join("static").join("stdx"), recursive: true)
        @Expect(hasStdxLibType(versionDir, "static"))
        @Expect(!hasStdxLibType(versionDir, "dynamic"))
        cleanup()
    }

    @TestCase
    func testEmptyVersionDir(): Unit {
        let versionDir = makeVersionDir("empty")
        @Expect(!hasStdxLibType(versionDir, "static"))
        @Expect(!hasStdxLibType(versionDir, "dynamic"))
        cleanup()
    }
}
