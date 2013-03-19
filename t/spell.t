#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Spelling;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Spelling

my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Spell $min_tp required for testing POD" if $@;

all_pod_files_spelling_ok();
				 