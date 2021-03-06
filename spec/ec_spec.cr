require "./spec_helper"

require "spec"
require "../src/openssl_ext/ec"

describe OpenSSL::EC do
  describe "instantiating and generate a key" do
    it "can instantiate and generate for a given key size" do
      pkey = OpenSSL::EC.new(384)
      pkey.private?.should be_true
      pkey.public?.should be_false

      pkey.public_key.public?.should be_true
    end
    it "can export to PEM format" do
      pkey = OpenSSL::EC.new(384)
      pkey.private?.should be_true

      pem = pkey.to_pem
      isEmpty = "-----BEGIN EC PRIVATE KEY-----\n-----END EC PRIVATE KEY-----\n" == pem

      pem.should contain("BEGIN EC PRIVATE KEY")
      isEmpty.should be_false
    end
    it "can export to DER format" do
      pkey = OpenSSL::EC.new(384)
      pkey.private?.should be_true
      pem = pkey.to_pem
      der = pkey.to_der

      pkey = OpenSSL::EC.new(der)
      pkey.to_pem.should eq pem
      pkey.to_der.should eq der
    end
    it "can instantiate with a PEM encoded key" do
      pem = OpenSSL::EC.new(384).to_pem
      pkey = OpenSSL::EC.new(pem)

      pkey.to_pem.should eq pem
    end
    it "can instantiate with a DER encoded key" do
      der = OpenSSL::EC.new(384).to_der
      pkey = OpenSSL::EC.new(der)

      pkey.to_der.should eq der
    end
  end
  describe "encrypting / decrypting" do
    it "should be able to sign and verify data" do
      ec = OpenSSL::EC.new(384)
      sha256 = OpenSSL::Digest::SHA256.new
      data = "my test data"
      sha256.update(data)
      digest = sha256.digest
      signature = ec.ec_sign(digest)

      ec.ec_verify(digest, signature).should be_true
    end
  end
end
