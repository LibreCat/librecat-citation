package Catmandu::Exporter::Citation;

use Catmandu::Sane;
use Catmandu::Exporter::Template;
use FindBin qw($Bin);
use Pandoc;
use Moo;
use namespace::clean;

with "Catmandu::Exporter";

has host  => (is => 'lazy');
has links => (is => 'ro', default => sub { 0 });
has name  => (is => 'ro', default => sub { 'LibreCat' });
has style => (is => 'lazy');
has format => (is => 'ro', default => sub { 'docx' });
has _exporter => (is => 'lazy');

sub _build_host {
    my ($self) = @_;
    state $host = Catmandu->config->{uri_base};
}

sub _build_style {
    my ($self) = @_;

    state $style = do {
        grep($self->style,
            keys %{Catmandu->config->{citation}->{csl}->{styles}})
            ? $self->style
            : Catmandu->config->{citation}->{csl}->{default_style};
    };
}

sub _build__exporter {
    my ($self) = @_;

    my $exp = Catmandu::Exporter::Template->new(
        template_before => "$Bin/../../../views/citation_before.tt",
        template => "$Bin/../../../views/citation.tt",
        template_after => "$Bin/../../../views/citation_after.tt",
        file => \$self->{_buffer},
    );
}

sub add {
    my ($self, $data) = @_;

    $data->{style} = $self->style;
    $data->{host} = $self->host;
    $data->{name} = $self->name;
    $data->{links} = $self->links;

    $self->_exporter->add($data);

}

sub commit {
    my ($self) = @_;

    $self->_exporter->commit;

    my $fh = $self->fh;
    my $fmt = $self->format;

    my $in = $self->{_buffer};

    my $out;
    pandoc -f => 'html', -t => $fmt, { in => \$in, out => $fh };
}

1;

=pod

=head1 NAME

Catmandu::Exporter::Word - an exporter to MS Word through HTML

=head2 SYNOPSIS

    use Catmandu::Exporter::Citation;

    my $pkg = Catmandu::Exporter::Word->new();

=cut
