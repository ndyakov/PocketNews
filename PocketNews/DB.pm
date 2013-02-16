package PocketNews::DB;

=pod

=head1 NAME

PocketNews::DB

=head1 SYNOPSIS

    use PocketNews::DB;
    ...
    my $db = PocketNews::DB->new(
                _filename =>'foo.sqlite',
            );

=head1 DESCRIPTION

DB wrapper

=head1 METHODS

=cut

use strict;
use warnings;
use DBI;
use Cwd;
use File::Util qw( SL );
our $VERSION = '0.05';

=pod

=head2 new

=over 1

=item Usage

        my $db = PocketNews::DB->new(
                    _filename =>"foo.sqlite",
                );

=back

=cut

sub new {
    my $class = shift;

    print "\n Executing $class v$VERSION..."
      if ( defined $::v or defined $::verbose );

    my $self = bless {@_}, $class;
    my $dir = getcwd . SL . 'PocketNews' . SL;
    $self->{_filename} = "default.sqlite" unless defined( $self->{_filename} );
    my $filename = $dir . $self->{_filename};
    print "\n Connecting to database file $filename..."
      if ( defined $::v or defined $::verbose );

    $self->{_dbh} = DBI->connect( "dbi:SQLite:dbname=$filename", "", "" )
      or die("DB connection error");

    print "done."
      if ( defined $::v or defined $::verbose );

    return $self;
}

=pod

=head2 exists

=over 3

=item Description

Check if this article exists in the database.

=item Usage

C<< $object->exists("title of the article"); >>

=item Return

Returns the count of the fields with such title.

=back

=cut

sub exists {
    my ( $self, $title ) = @_;
    my $sth = $self->{_dbh}->prepare(
        q{
         SELECT COUNT(*) FROM `news` WHERE `title` = ?;
    }
    );
    $sth->bind_param( 1, $title ) or die $self->{_dbh}->errstr;
    $sth->execute();
    return $sth->fetchrow_array;
}
1;

=pod

=head2 addNew

=over 3

=item Description

Add new article to the database.

=item Usage

C<< $object->addNew("title of the article"); >>

=item Return

return 1 on succes, -1 on error;

=back

=cut

sub addNew {
    my ( $self, $title ) = @_;
    my $sth = $self->{_dbh}->prepare(
        q{
         INSERT INTO `news` (`title`, `added`) VALUES (?,date('now'));
    }
    );
    $sth->bind_param( 1, $title ) or die $self->{_dbh}->errstr;
    $sth->execute();
    return $sth->rows;
}
1;

=pod

=head2 restoreAI

=over 3

=item Description

Subroutine for restorin the Auto Increment value to 0 for table.

=item Usage

C<< $db->restoreAI("Table"); >>

=item Return

Returns the number of affected rows 1 on succes otherwise -1.

=back

=cut

sub restoreAI {
    my ( $self, $table ) = @_;
    my $sth = $self->{_dbh}->prepare(
        q{
           UPDATE `SQLITE_SEQUENCE` SET `seq`=0 WHERE `name` = ?;
    }
    );
    $sth->bind_param( 1, $table ) or die $self->{_dbh}->errstr;
    $sth->execute();
    return $sth->rows;
}
1;

=pod

=head2 getLastId

=over 3

=item Description

Subroutine for getting the last Auto Increment value for table;

=item Usage

C<< $db->getLastId("Table"); >>

=item Return

Returns scalar - the last inserted id.

=back

=cut

sub getLastId {
    my ( $self, $table ) = @_;
    my $sth = $self->{_dbh}->prepare(
        q{
           SELECT `seq` FROM `SQLITE_SEQUENCE` WHERE `name` = ?;
    }
    );
    $sth->bind_param( 1, $table ) or die $self->{_dbh}->errstr;
    $sth->execute();
    my $row = $sth->fetchrow_hashref;
    return $row->{seq};
}
1;

sub clearTable {
	my ( $self, $table ) = @_;
	my $query = "DELETE FROM ".$table;
	my $rows_deleted = $self->{_dbh}->do($query);
	$self->restoreAI($table);
}
=pod

=head1 AUTHOR

ndyakov

=cut
