package App::PostImage::DB;
use Moo 2;

use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
use DBI;

=head1 NAME

App::PostImage::DB - database backend for user and image management

=head1 SYNOPSIS

  my $db = App::PostImage::DB->new(
      dsn => 'dbi:SQLite:dbfile=mydb.sqlite',
  );

You need SQLite 3.25.2 or any other database which includes
SQL window functions. These make the page logic basically trivial.

=cut

has 'dsn' => (
    is => 'ro',
);

has 'username' => (
    is => 'ro',
);

has 'password' => (
    is => 'ro',
);

has 'dbh' => (
    is => 'lazy',
    default => sub( $self ) {
        DBI->connect( $self->dbh, $self->username, $self->password,
            { RaiseError => 1, PrintError => 0 })
    },
);

sub _select( $self, $sql, @placeholders ) {
    my $res = $self->dbh->selectall_arrayref( $sql, { Slice => {}}, @placeholders );
    for( @$res ) {
        lock_hashref( $res );
    };
    $res
}

sub exec( $self, $sql, @placeholders ) {
    my $res = $self->execute( $sql, @placeholders );
}

sub _insert( $self, $table, $data ) {
    my $names = join",",map { qq("$_") } sort keys %$data;
    my $placeholders = join",",map { "?" } sort keys %$data;
    my @values = map { $data->{$_} } sort keys %$data;
    $self->exec( <<SQL, @values );
        insert into $table $names values ($placeholders)
SQL
}

sub _update( $self, $table, $data ) {
    my $id = delete $data->{id};
    my $names = join",",map { qq("$_ = ?") } sort keys %$data;
    my @values = map { $data->{$_} } sort keys %$data;
    $self->exec( <<SQL, @values, $id );
        update $table
           set $update
         where id = ?
SQL
}

sub _delete( $self, $table, $data ) {
    my $id = delete $data->{id};
    $self->exec( <<SQL, $id );
        delete from $table
         where id = ?
SQL
}

sub add_user( $self, $user ) {
    $self->_insert( 'users', $user )
}

sub get_user( $self, $name ) {
    $self->_select(<<'SQL', $name );
        select
            id
          , name
          -- , email
          from "users"
         where name = ?
SQL
}

sub update_user( $self, $user ) {
    $self->_update('users', $user);
}

sub delete_user( $self, $user_id ) {
    $self->_delete('users', $user);
}

sub add_image( $self, $image ) {
    $self->_insert( 'images', $image )
}

sub get_image( $self, $id ) {
    $self->_select(<<'SQL', $name );
        select
            id
          , filename
          , rank() over (partition by ... order by ...) as offset
          from "images"
         where id = ?
SQL
}

sub update_image( $self, $user ) {
    $self->_update('images', $user);
}

sub delete_image( $self, $image_id ) {
    $self->_delete('images', $user);
}

sub add_or_create_tag( $self, $name ) {
}

sub get_tag( $self, $id ) {
}

sub update_tag( $self, $tag ) {
}

sub delete_tag( $self, $tag_id ) {
    $self->_delete('tags', $tag_id )
}

sub add_image_tag( $self, $image_id, $tag_id ) {
}

sub delete_image_tag( $self, $image_id, $tag_id ) {
}

1;

