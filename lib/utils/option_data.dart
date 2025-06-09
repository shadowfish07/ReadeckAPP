sealed class OptionData<T> {
  const OptionData();
}

class Some<T> extends OptionData<T> {
  final T value;
  const Some(this.value);
}

class None<T> extends OptionData<T> {
  const None();
}
