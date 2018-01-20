module asn1.tools.encode_der;
import asn1.codecs.der;
import asn1.tools.encoder_mixin : Encoder;
mixin Encoder!DERElement;