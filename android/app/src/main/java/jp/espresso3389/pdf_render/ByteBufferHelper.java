package jp.espresso3389.pdf_render;

import java.nio.ByteBuffer;

/**
 * Heap-only stand-in for the upstream {@code ByteBufferHelper} from
 * the pdf_render plugin.
 *
 * The upstream version uses JNI to allocate direct ByteBuffers with
 * stable memory addresses that the Dart side accesses via FFI for
 * zero-copy transfer. That requires a bundled libbbhelper.so, which
 * we don't want to build from C++ source (no NDK in CI).
 *
 * For our use case (rendering a few hundred PDF pages over a long
 * reading session, not high-frequency updates), heap-allocated
 * ByteBuffers are fine — the plugin's render() method already has
 * a fallback path that returns {@code buf.array()} as a regular
 * byte array when no native address is available, and that's what
 * triggers here.
 *
 * Heap allocation has a small GC cost per page render (~2MB) but
 * that's acceptable for a one-time-per-page-cost at scroll time.
 */
class ByteBufferHelper {
  public static ByteBuffer newDirectBuffer(long ptr, long size) {
    // ptr is ignored — we always allocate a fresh heap buffer.
    return ByteBuffer.allocate((int) size);
  }

  public static long malloc(long size) {
    // Returning 0L signals to PdfRenderPlugin.render() to use the
    // buf.array() fallback path (which calls copyPixelsFromBuffer
    // semantics on the Dart side).
    return 0L;
  }

  public static void free(long ptr) {
    // No-op — heap GC will reclaim the ByteBuffer.
  }
}
