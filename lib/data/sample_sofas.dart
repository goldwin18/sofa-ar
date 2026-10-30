import 'models/sofa.dart';

/// The 10 sofas that ship with the app (real photos with the background removed).
///
/// The prices are placeholders, replace them with your own.
/// To add another one: drop `sofa_11.png` into assets/images and `sofa_11.glb` into
/// assets/models (tool/make_sample_glbs.py can build the .glb), then add a line below.
/// Widths are real-world metres and must match tool/make_sample_glbs.py.
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
    _sample('sofa_01', 'Sunset Orange Channel Sofa', 'Velvet', '₹42,999', 1.70),
    _sample('sofa_02', 'Orange & Cream Curved Sofa', 'Curved Designer', '₹89,500', 2.60),
    _sample('sofa_03', 'Navy Blue 3-Seater', 'Modern', '₹39,999', 2.10),
    _sample('sofa_04', 'Cream Tufted Loveseat', 'Classic', '₹34,750', 1.60),
    _sample('sofa_05', 'Emerald Velvet Sofa', 'Luxury Velvet', '₹56,999', 1.90),
    _sample('sofa_06', 'Ivory Channel 3-Seater', 'Contemporary', '₹72,400', 2.30),
    _sample('sofa_07', 'Natural Wood Frame Sofa', 'Scandinavian', '₹48,250', 2.00),
    _sample('sofa_08', 'Tan Leather Recliner', 'Leather', '₹84,900', 1.85),
    _sample('sofa_09', 'Grey Bouclé Curved Sofa', 'Bouclé', '₹78,300', 2.30),
    _sample('sofa_10', 'Sage Teal 2-Seater', 'Mid-century', '₹37,600', 1.70),
  ];
}
