package App::PostImage;
use strict;

use Moo 2;

use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
use Path::Class 'dir';
use FindBin;
use YAML 'LoadFile';
use App::PostImage::DB;

our $VERSION = '0.01';

=head1 NAME

App::PostImage - simple image blog

=cut

has 'config_file' => (
    is => 'ro',
    default => sub {
        "$FindBin::Bin/../config.yml"
    },
);

has 'config' => (
    is => 'lazy',
    default => sub( $self ) { $self->load_config_file( filename => $self->config_file ) },
);

has 'db' => (
    is => 'lazy',
    default => sub( $self ) {
        App::PostImage::DB->new(
            dsn => $self->config->{db}->{dsn},
            username => $self->config->{db}->{username},
            password => $self->config->{db}->{password},
        ),
    },
);

sub load_config_file( $self, %options ) {
    LoadFile($self->config_file);
}

=head2 C<< $self->check_config >>

  my ($has_errors, @messages) = $app->check_config();
  warn for @messages;
  if( $has_errors > 1 ) {
      exit $errors;
  };

Checks the configuration and returns the suggested exit code. For configuration
warnings, this will be 1, for errors that make it impossible to use this
configuration, this will be 2 or larger.

=cut

sub check_config( $self, $config = $self->config ) {
    my (@warnings, @fatal);
    
    for my $dir (sort keys %{ $config->{directories}}) {
        my $path = dir( $config->{directories}->{$dir} );
        if( ! $path->is_absolute ) {
            push @warnings, "Directory '$dir': The path '$path' is not an absolute path.";
        };
        if( ! -d $path ) {
            push @fatal, "Directory '$dir': The path '$path' does not exist.";
        } elsif( ! -r $path ) {
            push @fatal, "Directory '$dir': The path '$path' is not readable for the current user.";
        } elsif( ! -w $path ) {
            push @fatal, "Directory '$dir': The path '$path' is not writeable for the current user.";
        };
    };
    
    # check that the admin password has been changed from the default
    if( $config->{admin} eq '' ) {
        push @fatal, "The administrator password is still the default password.";
    };

    # check that the nonce has been changed from the default
    if( $config->{nonce} eq '' ) {
        push @fatal, "The site secret nonce is still the default nonce.";
    };
    
    for my $key (qw(revalidate expires)) {
        if( $config->{session}->{$key} !~ /^\d+$/ ) {
            push @fatal, "Session '$key' must be a number of days.";
        };
    };
    
    # Check that the database connection works
    if( $config == $self->config ) {
        if(! eval {
            my $db = $self->db;
            1
        }) {
            push @fatal, "Couldn't connect to database ($config->{db}->{dsn}, $config->{db}->{username}): $@";
        };
    };
    
    # XXX check that all the URLs are reachable
    
    my @messages = (@fatal, @warnings);
    my $status =   0+@fatal    ? 2
                 : 0+@warnings ? 1
                 :               0;
    
    ($status, @messages)
    
};

sub upload_dir($self) {
    $self->config->{directories}->{upload}
}

sub docroot_dir($self) {
    $self->config->{directories}->{docroot}
}

sub add_image( $self, $filename, $username, $tags ) {
    # Store metadata for later easy templating
    my $image = $self->db->add_image(
        width => 0,
        height => 0,
        filename => $filename,
        external_filename => $filename,
        user => $user,
        tags => \@tags,
    );
    # resize to target resolutions
    # recreate HTML
    # recreate RSS
}

sub create_image_html( $self, $image_id ) {
    
}

1;