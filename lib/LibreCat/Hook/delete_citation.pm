package LibreCat::Hook::delete_citation;

use Catmandu::Sane;
use LibreCat::Citation;
use Moo;

has citation => (is => 'lazy');

sub _build_citation {
    LibreCat::Citation->new();
}

sub fix {
    my ($self, $data) = @_;

    my $citation = $self->citation->delete($data);

    return $data;
}

1;

=pod

=head1 NAME

LibreCat::Hook::delete_citation - delete citations from citation-db

=head2 SYNOPSIS

    # in your config
    hooks:
      publication-delete:
        after_fixes:
         - delete_citation

=cut
