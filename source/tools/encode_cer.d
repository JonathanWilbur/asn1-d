module asn1.tools.encode_cer;
import asn1.codecs.cer;
import asn1.tools.encoder_mixin : Encoder;
mixin Encoder!CERElement;