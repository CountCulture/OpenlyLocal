# https://github.com/jhawthorn/dkim
Dkim::domain      = 'openlylocal.com'
Dkim::selector    = 'mail'
Dkim::private_key = File.read(File.join(Rails.root, 'config', 'openlylocal.com.priv'))
# @see http://docs.amazonwebservices.com/ses/latest/DeveloperGuide/DKIM.html
# @see https://github.com/jhawthorn/dkim/blob/master/lib/dkim.rb
Dkim::signable_headers = Dkim::DefaultHeaders - %w(Message-ID Date Return-Path Bounces-To)

# The selector record:
#
#     mail._domainkey.openlylocal.com TXT v=DKIM1;t=s;n=core;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDXW0G0z6S7ZidpdiG0OEyl4s/6k9sH2pHsggJzOvfVUKMvQQ6bFT2Zt04X3dpN5nDTVsKrozStO+7PNzVe+DHpAHuLrL9JQd31p75BkIfjzU4ua0ZBIUk1hK6sa3UwqpmkoaRrKGzKgadG4VLoWmMMMr/MMdnuaHb2e/lcjDLHlwIDAQAB
#
# Various tutorials specify k=rsa and g=*, although they are the default.
#
# @see http://dkimcore.org/specification.html
# @see http://dkim.org/specs/rfc4871-dkimbase.html
# @see http://domainkeys.sourceforge.net/selectorcheck.html

# The policy record:
#
#     _domainkey.openlylocal.com TXT t=y;o=~;r=admin@openlylocal.com
#
# @see http://www.ietf.org/rfc/rfc4870.txt
# @see http://domainkeys.sourceforge.net/policycheck.html
