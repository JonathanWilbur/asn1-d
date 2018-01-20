module asn1.tools.decode_der;
import asn1.codecs.der;
import asn1.tools.decoder_mixin : Decoder;
mixin Decoder!DERElement;