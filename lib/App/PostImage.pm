package App::PostImage;
use strict;

use Moo 2;

use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

our $VERSION = '0.01';

has 'config' => (
    is => 'ro',
);

1;