/// A sofa the customer can look at, place in AR, or overlay on the camera.
class Sofa {
  const Sofa({
    required this.id,
    required this.name,
    required this.imagePath,
    this.style = '',
    this.price = '',
    this.widthMeters,
    this.modelPath,
    this.isAsset = true,
  });

  final String id;
  final String name;
  final String style;
  final String price;

  /// Real-world width in metres (used to size the generated 3D model).
  final double? widthMeters;

  /// Picture of the sofa. An asset path for samples, a file path for user sofas.
  final String imagePath;

  /// The .glb 3D model, if there is one. Same asset/file rule as [imagePath].
  final String? modelPath;

  /// true = bundled with the app, false = added by the user (stored on the phone).
  final bool isAsset;

  bool get hasModel => modelPath != null;

  /// What the 3D viewer should load. Local files need the file:// prefix.
  String? get viewerSource {
    final path = modelPath;
    if (path == null) return null;
    return isAsset ? path : 'file://$path';
  }

  Sofa copyWith({String? modelPath}) => Sofa(
        id: id,
        name: name,
        imagePath: imagePath,
        style: style,
        price: price,
        widthMeters: widthMeters,
        modelPath: modelPath ?? this.modelPath,
        isAsset: isAsset,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'style': style,
        'price': price,
        'widthMeters': widthMeters,
        'imagePath': imagePath,
        'modelPath': modelPath,
        'isAsset': isAsset,
      };

  factory Sofa.fromJson(Map<String, dynamic> json) => Sofa(
        id: json['id'] as String,
        name: json['name'] as String,
        style: (json['style'] as String?) ?? '',
        price: (json['price'] as String?) ?? '',
        widthMeters: (json['widthMeters'] as num?)?.toDouble(),
        imagePath: json['imagePath'] as String,
        modelPath: json['modelPath'] as String?,
        isAsset: (json['isAsset'] as bool?) ?? false,
      );
}
