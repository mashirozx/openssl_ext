module OpenSSL::X509
  class Certificate
    class CertificateError < OpenSSL::Error; end

    def initialize
      @cert = LibCrypto.x509_new
      raise Error.new("X509_new") if @cert.null?

      self.version = 2
      self.serial = random_serial
    end

    def self.new(pem : String)
      io = IO::Memory.new(pem)
      bio = OpenSSL::GETS_BIO.new(io)
      x509 = LibCrypto.pem_read_bio_x509(bio, nil, nil, nil)

      raise CertificateError.new "Could not read PEM" unless x509
      new x509
    end

    def self.from_pem(pem : String)
      self.new(pem)
    end

    def self.from_pem(io : IO)
      self.new(io.gets_to_end)
    end

    def version
      LibCrypto.x509_get_version(self)
    end

    def version=(n : Int32)
      LibCrypto.x509_set_version(self, 2_i64)
    end

    def serial
      sn = LibCrypto.x509_get_serialnumber(self)
      LibCrypto.asn1_integer_get(sn)
    end

    def serial=(index : Int64)
      sn = LibCrypto.x509_get_serialnumber(self)
      LibCrypto.asn1_integer_set(sn, index)
    end

    def issuer
      issuer = LibCrypto.x509_get_issuer_name(self)
      raise CertificateError.new "Can not get issuer" unless issuer

      Name.new(issuer)
    end

    def issuer=(subject : Name)
      LibCrypto.x509_set_issuer_name(self, subject)
    end

    def public_key
      begin
        pkey = LibCrypto.x509_get_public_key(self)
        RSA.new(pkey, false)
      rescue
        raise CertificateError.new "X509_get_pubkey"
      end
    end

    def public_key=(pkey)
      LibCrypto.x509_set_public_key(self, pkey)
    end

    def not_before=(time : ASN1::Time)
      LibCrypto.x509_set_notbefore(self, time)
    end

    def not_after=(time : ASN1::Time)
      LibCrypto.x509_set_notafter(self, time)
    end

    def sign(pkey : OpenSSL::PKey, digest : Digest)
      if LibCrypto.x509_sign(self, pkey.to_unsafe, digest.to_unsafe_md) == 0
        raise CertificateError.new("X509_sign")
      end
    end

    def to_pem(io)
      bio = OpenSSL::GETS_BIO.new(io)
      raise CertificateError.new "Could not convert to PEM" unless LibCrypto.pem_write_bio_x509(bio, self)
    end

    def to_pem
      io = IO::Memory.new
      to_pem(io)
      io.to_s
    end

    def to_unsafe_pointer
      pointerof(@cert)
    end

    private def random_serial
      long = uninitialized Int64
      ptr = pointerof(long).as Int32*
      ptr[0] = rand(Int32::MIN..Int32::MAX)
      ptr[1] = rand(Int32::MIN..Int32::MAX)
      long
    end
  end
end
