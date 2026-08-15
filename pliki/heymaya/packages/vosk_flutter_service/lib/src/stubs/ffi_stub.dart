/// Stub for dart:ffi and package:ffi
library;

class NativeType {
  const NativeType();
}

class Opaque extends NativeType {
  const Opaque();
}

class Void extends NativeType {}

class Char extends NativeType {}

class Float extends NativeType {}

class Uint8 extends NativeType {
  @override
  bool operator ==(Object other) => true;

  @override
  int get hashCode => 0;
}

class Uint32 extends NativeType {}

class Int32 extends NativeType {}

class Int extends NativeType {}

class Short extends NativeType {}

class Double extends NativeType {}

class Handle extends NativeType {}

class Bool extends NativeType {}

class Pointer<T extends NativeType> extends NativeType {
  const Pointer.fromAddress(int address) : super();
  int get address => 0;
  T operator [](int index) => throw UnimplementedError();
  void operator []=(int index, T value) => throw UnimplementedError();
  Pointer<U> cast<U extends NativeType>() => Pointer<U>.fromAddress(0);
  external T get value;
  external set value(T value);
  external Pointer<T> operator +(int offset);
  external Pointer<T> operator -(int offset);
  external Pointer<T> elementAt(int index);
  external void free();
  dynamic asTypedList(int length) => throw UnimplementedError();
  external R asFunction<R extends Function>();
}

extension PointerPointerPrefix on Pointer<Pointer<NativeType>> {
  external Pointer<NativeType> get value;
  external set value(Pointer<NativeType> value);
}

class Allocator {
  Pointer<T> call<T extends NativeType>([int count = 1]) =>
      Pointer<T>.fromAddress(0);
  void free(Pointer<NativeType> pointer) {}
}

final Pointer<Never> nullptr = Pointer<Never>.fromAddress(0);

class DynamicLibrary {
  static DynamicLibrary open(String path) => DynamicLibrary();
  Pointer<T> lookup<T extends NativeType>(String symbolName) =>
      Pointer<T>.fromAddress(0);
}

class NativeFunction<T extends Function> extends NativeType {}

// From package:ffi
T using<T>(
  T Function(Allocator arena) callback, [
  void Function(Pointer<NativeType>)? cleanup,
]) {
  return callback(Allocator());
}

class Arena extends Allocator {
  @override
  Pointer<T> call<T extends NativeType>([int count = 1]) =>
      Pointer<T>.fromAddress(0);
  @override
  void free(Pointer<NativeType> pointer) {}
  void releaseAll() {}
}

typedef VoidNative = void;
