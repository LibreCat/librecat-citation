package LibreCat::Hook::add_citation;

use Catmandu::Sane;
use LibreCat::Citation;
use Moo;

has citation => (is => 'lazy');

sub _build_citation {
    LibreCat::Citation->new();
}

sub fix {
    my ($self, $data) = @_;

    my $citation = $self->citation->add($data);

    return $data;
}

1;

=pod

=head1 NAME

LibreCat::Hook::add_citation - add a 'citation' object calculated from the data

=head2 SYNOPSIS

    # in your config
    hooks:
      publication-update:
        after_fixes:
          - add_citation

=cut
