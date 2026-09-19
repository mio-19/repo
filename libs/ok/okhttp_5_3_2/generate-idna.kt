@file:JvmName("GenerateIdnaMain")

package okhttp3.internal.idn

import java.io.File
import okio.FileSystem
import okio.Path.Companion.toPath

fun main(vararg args: String) {
  val data = loadIdnaMappingTableData()
  val outDir = File(args[0])
  val out = File(outDir, "okhttp3/internal/idn/IdnaMappingTableInstance.kt")
  out.parentFile.mkdirs()
  out.writeText(
    """
    |package okhttp3.internal.idn
    |
    |internal val IDNA_MAPPING_TABLE: IdnaMappingTable = IdnaMappingTable(
    |  sections = "${data.sections.escapeDataString()}",
    |  ranges = "${data.ranges.escapeDataString()}",
    |  mappings = "${data.mappings.escapeDataString()}",
    |)
    |
    """.trimMargin(),
  )
}

fun loadIdnaMappingTableData(): IdnaMappingTableData {
  val path = "/okhttp3/internal/idna/IdnaMappingTable.txt".toPath()
  val table =
    FileSystem.RESOURCES.read(path) {
      readPlainTextIdnaMappingTable()
    }
  return buildIdnaMappingTableData(table)
}

/** Escape string literals so they are safe in generated Kotlin source. */
fun String.escapeDataString(): String =
  buildString {
    for (codePoint in this@escapeDataString.codePoints()) {
      when (codePoint) {
        in 0..0x20,
        '"'.code,
        '$'.code,
        '\\'.code,
        '·'.code,
        127,
        -> append(String.format("\\u%04x", codePoint))

        else -> appendCodePoint(codePoint)
      }
    }
  }
