package androidx.annotation

/**
 * Minimal compile-only stub of androidx.annotation.VisibleForTesting.
 * Upstream kotlinx-coroutines-android only needs the annotation for API metadata.
 */
@MustBeDocumented
@Retention(AnnotationRetention.BINARY)
@Target(
  AnnotationTarget.FUNCTION,
  AnnotationTarget.PROPERTY_GETTER,
  AnnotationTarget.PROPERTY_SETTER,
  AnnotationTarget.CONSTRUCTOR,
  AnnotationTarget.FIELD,
  AnnotationTarget.CLASS,
)
annotation class VisibleForTesting(
  val otherwise: Int = PRIVATE,
) {
  companion object {
    const val PRIVATE = 2
    const val PACKAGE_PRIVATE = 3
    const val PROTECTED = 4
    const val NONE = 5
  }
}
