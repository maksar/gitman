
source <(sed -E "s/[^#]+/export &/g" .env) && ruby server.rb

rubocop -a && deep-cover clone rspec && open coverage/index.html

add access to repo