
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Generate metadata for a module",
  "dist_author" => [
    "Steven Haryanto <stevenharyanto\@gmail.com>"
  ],
  "dist_name" => "Perinci-Gen-ForModule",
  "dist_version" => "0.03",
  "license" => "perl",
  "module_name" => "Perinci::Gen::ForModule",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Exporter::Lite" => 0,
    "Rinci" => "1.1.0",
    "SHARYANTO::Array::Util" => 0,
    "SHARYANTO::Package::Util" => "0.20",
    "Test::More" => "0.96",
    "perl" => "5.010000"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
