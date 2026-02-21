part of 'farmer_bloc.dart';

sealed class FarmerEvent extends Equatable {
  const FarmerEvent();
  @override
  List<Object?> get props => [];
}

final class FarmerLoadRequested extends FarmerEvent {
  const FarmerLoadRequested();
}

final class FarmerSearchRequested extends FarmerEvent {
  const FarmerSearchRequested(this.query);
  final String query;
  
  @override
  List<Object?> get props => [query];
}

final class FarmerCreateRequested extends FarmerEvent {
  const FarmerCreateRequested(this.farmer);
  final FarmerEntity farmer;
  
  @override
  List<Object?> get props => [farmer];
}

final class FarmerUpdateRequested extends FarmerEvent {
  const FarmerUpdateRequested(this.farmer);
  final FarmerEntity farmer;
  
  @override
  List<Object?> get props => [farmer];
}

final class FarmerDeleteRequested extends FarmerEvent {
  const FarmerDeleteRequested(this.id);
  final String id;
  
  @override
  List<Object?> get props => [id];
}

final class FarmerLoadByIdRequested extends FarmerEvent {
  const FarmerLoadByIdRequested(this.id);
  final String id;
  
  @override
  List<Object?> get props => [id];
}

final class FarmerFilterByClassificationRequested extends FarmerEvent {
  const FarmerFilterByClassificationRequested(this.classification);
  final FarmerClassification classification;
  
  @override
  List<Object?> get props => [classification];
}

final class FarmerFilterByVillageRequested extends FarmerEvent {
  const FarmerFilterByVillageRequested(this.village);
  final String village;
  
  @override
  List<Object?> get props => [village];
}
