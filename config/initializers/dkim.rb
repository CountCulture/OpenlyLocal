# https://github.com/jhawthorn/dkim
Dkim::domain      = 'openlylocal.com'
Dkim::selector    = 'mail'
# @see http://docs.amazonwebservices.com/ses/latest/DeveloperGuide/DKIM.html
# @see https://github.com/jhawthorn/dkim/blob/master/lib/dkim.rb
Dkim::signable_headers = Dkim::DefaultHeaders - %w(Message-ID Date Return-Path Bounces-To)

private_key = File.join(Rails.root, 'config', 'openlylocal.com.priv')
Dkim::private_key = File.read(private_key) if File.exist?(private_key)

# The selector record:
#
#     mail._domainkey.openlylocal.com TXT v=DKIM1;t=s;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDXW0G0z6S7ZidpdiG0OEyl4s/6k9sH2pHsggJzOvfVUKMvQQ6bFT2Zt04X3dpN5nDTVsKrozStO+7PNzVe+DHpAHuLrL9JQd31p75BkIfjzU4ua0ZBIUk1hK6sa3UwqpmkoaRrKGzKgadG4VLoWmMMMr/MMdnuaHb2e/lcjDLHlwIDAQAB
#
# RFC 4871 recommends "v=DKIM1" and, unless subdomains are used, "t=s".
#
# http://dkimcore.org/specification.html sets "n=core", but this tag is for
# notes of interest to humans, that are not interpreted by any program.
#
# Various tutorials specify k=rsa and g=*, but these are the defaults.
#
# @see http://www.ietf.org/rfc/rfc4871.txt
# @see http://domainkeys.sourceforge.net/selectorcheck.html

# The policy record:
#
#     _domainkey.openlylocal.com TXT t=y;o=~;r=admin@openlylocal.com
#
# @see http://www.ietf.org/rfc/rfc4870.txt
# @see http://domainkeys.sourceforge.net/policycheck.html

# For mail sent through Google Apps, see:
# @see http://support.google.com/a/bin/answer.py?hl=en&answer=174124

# Handy testing tools:
# * send an email to check-auth@verifier.port25.com and get a report in reply
# * http://www.brandonchecketts.com/emailtest.php
