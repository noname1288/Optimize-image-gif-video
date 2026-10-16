sealed class Failure {
  const Failure(this.message);
  final String message;
}

class DataFailure extends Failure {
  const DataFailure(super.message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
