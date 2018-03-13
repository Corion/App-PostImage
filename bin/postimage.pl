#!perl -w
use Mojolicious::Lite;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

use Path::Class 'dir';
use FindBin;

use Mojo::Util 'hmac_sha1_sum';

use YAML 'LoadFile';
my $config = LoadFile("$FindBin::Bin/../config.yml");

app->moniker( $config->{admin} );
app->secrets([ $config->{nonce} ]);

# XXX Sanity-check directories

push @{app->static->paths}, dir($config->{directories}->{docroot})->absolute->stringify;

# / should be handled as a static file, /index.html!
get '/' => sub( $c ) {
    return $c->redirect_to('/index.html');
};

#get '/setup' => sub( $c ) {
#    # this should be static
#    # name
#    $c->render('setup.html');
#};

sub auth_url( $prefix, $username ) {
    my $key = hmac_sha1_sum($username, $config->{admin});
    my $auth_url = sprintf '/%s/%s/%s', $prefix, $username, $key;
}

post '/setup' => sub( $c ) {
    my $admin_password = $c->param('password');
    my $username = $c->param('name');
    $username =~ s!/!!g;

    if( ! length $username ) {
        return $c->redirect_to( '/' );
    };

    if( $admin_password ne $config->{admin} ) {
        return $c->redirect_to( '/setup.html' );
    };

    my $auth_url = auth_url( 'login', $username );
    my $qr_image_url = auth_url( 'qr', $username ) . ".png";

    # show QR code of result, and insta-use URL for the client to access
    $c->stash( auth_url => $auth_url );
    $c->stash( qr_url => $qr_image_url );
    $c->stash( name => $username );
    $c->render(template => 'setup', format => 'html');
};


get 'qr/:name/(:key).png' => sub($c) {
    my $username = $c->param('name');
    my $key = $c->param('key');
    my $url = $config->{urls}->{public_url} . "login/$username/$key";
    use Imager::QRCode 'plot_qrcode';
    my $img = plot_qrcode($url, {
        size          => 2,
        margin        => 2,
        version       => 1,
        level         => 'M',
        casesensitive => 1,
        lightcolor    => Imager::Color->new(255, 255, 255),
        darkcolor     => Imager::Color->new(0, 0, 0),
    });
    $img->write(data => \my $qr, type => 'png')
      or die "Failed to write: " . $img->errstr;
    return $c->render( data => $qr, format => 'png' );
};

get 'login/:name/:key' => sub( $c ) {
    my $username = $c->param('name');
    my $key = $c->param('key');
    # validate key
    my $expected = hmac_sha1_sum($username, $config->{admin});
    if( $expected ne $key ) {
        return $c->redirect_to( '/' );
    };

    my $session = $c->session;
    $session->{authenticated} = 1;
    $session->{name} = $c->param('name');
    $c = $c->session( $session );
    $c->session(expires => time + 365*24*3600);

    $c->redirect_to('/upload.html');
};

post 'post' => sub( $c ) {
    #my $app = App::PostImage->new(
    #    config => $config,
    #);
    if( ! $c->session->{authenticated} ) {
        $c->redirect_to('/index.html');
    };

    # Save to local storage
    my $file = $c->param('file');
    my $name = sprintf "%s/img-%d.jpg", $config->{directories}->{upload}, time();
    $file->move_to( $name );

    #my $ok = $app->add_image(
    #);
    #if( $ok ) {
    #    $app->regenerate_image_list();
    #};
};

app->start;

__DATA__
@@setup.html.ep
<!DOCTYPE html>
<html>
<h1><%= $name %></h1>
<a href="<%= $auth_url %>">Auth URL login</a>
<img src="<%= $qr_url %>" alt="QR code for logging in">
</html>
