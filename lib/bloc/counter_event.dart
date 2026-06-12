part of 'counter_bloc.dart';

@immutable
sealed class CounterEvent {}

class CounterIncremented extends CounterEvent {}

class CounterDecremented extends CounterEvent {}
