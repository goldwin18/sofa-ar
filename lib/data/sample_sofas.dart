import 'models/sofa.dart';

/// The 10 sofas that ship with the app.
///
/// To add another one: drop `sofa_11.glb` into assets/models, `sofa_11.png`
/// into assets/images, and add a line below.
class SampleSofas {
  SampleSofas._();

  static Sofa _sample(String id, String name, String style, String price, double width) {
    return Sofa(
      id: id,
      name: name,
      style: style,
      price: price,
      widthMeters: width,
      imagePath: 'assets/images/$id.png',
      modelPath: 'assets/models/$id.glb',
    );
  }

  static final List<Sofa> all = [
    _sample('sofa_01', 'Nordic Grey 3-Seater', 'Scandinavian', '₹42,999', 2.10),
    _sample('sofa_02', 'Velvet Emerald 2-Seater', 'Modern Velvet', '₹36,499', 1.65),
    _sample('sofa_03', 'Classic Tan Leather 3-Seater', 'Leather', '₹78,500', 2.20),
    _sample('sofa_04', 'Navy Blue Loveseat', 'Compact', '₹29,999', 1.50),
    _sample('sofa_05', 'Sand Beige L-Shape Sectional', 'Sectional', '₹64,999', 3.20),
    _sample('sofa_06', 'Blush Pink Accent Sofa', 'Boho', '₹33,250', 1.80),
    _sample('sofa_07', 'Charcoal Modern 4-Seater', 'Contemporary', '₹58,750', 2.80),
    _sample('sofa_08', 'Mustard Retro 2-Seater', 'Mid-century', '₹31,400', 1.70),
    _sample('sofa_09', 'Ivory Cloud Lounge Sofa', 'Lounge', '₹69,900', 2.40),
    _sample('sofa_10', 'Teal Sofa with Ottoman', 'Modern', '₹47,800', 2.00),
  ];
}
