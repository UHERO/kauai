source 'https://rubygems.org'

require 'json'
require 'open-uri'
versions = JSON.parse(open('https://pages.github.com/versions.json').read)

require 'webrick'
#include WEBrick

WEBrick::HTTPUtils::DefaultMimeTypes.store 'svg', 'image/svg+xml'

gem 'github-pages', versions['github-pages']
