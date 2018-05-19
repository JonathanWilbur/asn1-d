# This wont work until I recalculate the hash. This should be next commit. Sorry.
class Asn1D < Formula
  desc "ASN.1 Codecs, including BER, CER, and DER"
  homepage "https://github.com/JonathanWilbur/asn1-d"
  url "https://github.com/JonathanWilbur/asn1-d/archive/v2.4.3.tar.gz"
  version = "2.4.3"
  sha256 "e86694b2e15d8d4da2477c44e584fb5e860666787d010801199a0a77bcf28a2d"

  def install
    system '/usr/local/bin/dmd', \
      './source/macros.ddoc', \
      './source/asn1/codec.d', \
      './source/asn1/compiler.d', \
      './source/asn1/constants.d', \
      './source/asn1/interfaces.d', \
      './source/asn1/types/alltypes.d', \
      './source/asn1/types/identification.d', \
      './source/asn1/types/oidtype.d', \
      './source/asn1/types/universal/characterstring.d', \
      './source/asn1/types/universal/embeddedpdv.d', \
      './source/asn1/types/universal/external.d', \
      './source/asn1/types/universal/objectidentifier.d', \
      './source/asn1/codecs/ber.d', \
      './source/asn1/codecs/cer.d', \
      './source/asn1/codecs/der.d', \
      '-Dd./documentation/html', \
      '-Hd./output/interfaces', \
      '-op', \
      "-of./output/libraries/asn1-#{version}.so", \
      '-lib', \
      '-inline', \
      '-release', \
      '-O', \
      '-d'

    Dir.glob('./source/tools/encode_*.d') do |file|
      encoder_source = File.basename(file)
      encoder_executable = encoder_source.sub('_', '-').sub('.d', '')
      system '/usr/local/bin/dmd', \
        '-I./output/interfaces/source', \
        "-L./output/libraries/asn1-#{version}.so", \
        './source/tools/encoder_mixin.d', \
        "./source/tools/#{encoder_source}", \
        '-od./output/objects', \
        "-of./output/executables/#{encoder_executable}", \
        '-inline', \
        '-release', \
        '-O', \
        '-d'
    end

    Dir.glob('./source/tools/decode_*.d') do |file|
      decoder_source = File.basename(file)
      decoder_executable = decoder_source.sub('_', '-').sub('.d', '')
      system '/usr/local/bin/dmd', \
        '-I./output/interfaces/source', \
        "-L./output/libraries/asn1-#{version}.so", \
        './source/tools/decoder_mixin.d', \
        "./source/tools/#{decoder_source}", \
        '-od./output/objects', \
        "-of./output/executables/#{decoder_executable}", \
        '-inline', \
        '-release', \
        '-O', \
        '-d'
    end

    lib.install "./output/libraries/asn1-#{version}.so"
    ln_sf lib/"asn1_#{version}.so", lib/'asn1.so'
    bin.install Dir['./output/executables/*']
    man1.install Dir['./documentation/man/1/*']
    doc.install Dir['./documentation/*.md']
    doc.install Dir['./documentation/html']
    doc.install "./documentation/asn1-#{version}.json"
    doc.install './documentation/mit.license'
    doc.install './documentation/credits.csv'
    doc.install './documentation/releases.csv'
  end

  test do
    system "#{bin}/encode-der [UP6]::=oid:1.3.4.6.1.65537.256.9 > test.der"
    system "cat test.der | #{bin}/decode-der | grep 1.3.4.6.1.65537.256.9"
  end
end
