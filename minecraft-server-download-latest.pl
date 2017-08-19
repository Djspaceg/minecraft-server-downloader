#!/usr/bin/perl
$|++;  # Disable buffering, for continuous output.

use LWP::UserAgent;
use JSON qw( decode_json );
use Data::Dumper;
use Cwd;
use strict;
use warnings;

### URL to the Minecraft version manifest.
my $version_manifest = 'https://launchermeta.mojang.com/mc/game/version_manifest.json';

### A tokenized string for the Minecraft server file. use `{version}` to substitute it for the requested verison.
### https://s3.amazonaws.com/Minecraft.Download/versions/1.12.1/minecraft_server.1.12.1.jar
my $mc_download_url = 'https://s3.amazonaws.com/Minecraft.Download/versions/{version}/minecraft_server.{version}.jar';

### The download file name. What do you want to call the file that is downloaded.
my $mc_downloaded_file = 'minecraft_server.{version}.jar';

# The file used by your server, this will be a symlink pointing to the latest verison.
my $server_file = 'minecraft_server.jar';


### ACTUAL CODE BELOW ### NO NEED TO EDIT #####################################


# Setup browser
my $ua = LWP::UserAgent->new(
	ssl_opts => { verify_hostname => 0 },
	protocols_allowed => ['https'],
);

print "Getting latest version...";

# Set up request for manifest
my $req = HTTP::Request->new(
	GET => $version_manifest,
);

# Get the response from the request
my $res = $ua->request($req);
die "Could not get $version_manifest! Remote server not coperating; error#" . $res->code unless ($res->code == 200);

# print Dumper $res->content;

# Decode the entire JSON
my $decoded_json = decode_json( $res->content );

# print Dumper $decoded_json;

my $mc_version = $decoded_json->{'latest'}->{'release'};
print " Latest version: $mc_version\n";

# De-tokenize the config strings
my $real_url = InsertVersion($mc_version, $mc_download_url);
my $real_file = InsertVersion($mc_version, $mc_downloaded_file);

# Prepare and request the download file
print "Downloading $real_url...";
my $dl_req = HTTP::Request->new(GET => $real_url);
my $dl_res = $ua->request($dl_req, $real_file);
print "Done\n";


my $dir = getcwd();
print "Download finished. File saved to $dir/$real_file\n";

# Symlink that file
-e $server_file and unlink $server_file;
symlink $real_file, $server_file;
print "Symlinked $mc_version as $server_file\n";


### Subs ###

sub InsertVersion {
	my $ver = shift();
	my $instr = shift();
	$instr =~ s/\{version\}/$ver/g;
	return $instr;
}
