package LibreCat::Citation::CSL;

use Catmandu::Sane;
use LibreCat::App::Helper;
use Catmandu qw(export_to_string);
use Catmandu::Util qw(:array);
use Clone qw(clone);
use LWP::UserAgent;
use Encode qw(encode_utf8);
use URI ();
use Moo;
use namespace::clean;

with 'Catmandu::Logger';

has style  => (is => 'ro');
has locale => (is => 'ro', default => sub {'en'});
has all    => (is => 'ro');

has conf      => (is => 'lazy');
has styles    => (is => 'lazy');
has csl_fixer => (is => 'lazy');

sub _build_conf {
    LibreCat::App::Helper::Helpers->new->config->{citation};
}

sub _build_styles {
    my ($self) = @_;
    if ($self->all) {
        return [keys %{$self->conf->{csl}->{styles}}];
    }
    elsif ($self->style) {
        return [$self->style];
    }
    else {
        return [$self->conf->{csl}->{default_style}];
    }
}

sub _build_csl_fixer {
    h->create_fixer('to_csl.fix');
}

sub _request {
    my ($self, $data) = @_;

    my $ua = LWP::UserAgent->new();

    my $uri = URI->new($self->conf->{csl}->{url});
    $uri->query_form(
        {responseformat => 'html', linkwrap => 1, style => $data->{style}});

    my $res = $ua->post($uri->as_string(),
        Content => encode_utf8($data->{content}));

    if ($res->{_rc} eq '200') {
        $self->log->debug("200 OK for " . $uri->as_string());

        my $content = $res->{_content};
        $content =~ s/<div class="csl-left-margin">.*?<\/div>//g;
        $content =~ s/<div.*?>|<\/div>//g;

        # More regexes for backwards compatibility
        $content =~ s/^\s+//g;
        $content =~ s/\s+$//g;
        $content =~ s/__LINE_BREAK__/\<br \/\>/g;
        utf8::decode($content);
        return $content;
    }
    else {
        $self->log->error("Error: " . $res->{_rc});
        return undef;
    }
}

sub create {
    my ($self, $data) = @_;

    my $cite = {};

    my $engine = $self->conf->{engine} // 'none';

    if (0) { }
    elsif ($engine eq 'csl') {
        my $d         = clone $data;
        my $csl_fixer = $self->csl_fixer;
        my $csl_json  = export_to_string($d, 'JSON',
            {line_delimited => 1, fix => $csl_fixer});

        my $found = 0;
        foreach my $s (@{$self->styles}) {
            my $locale   = ($s eq 'dgps') ? 'de' : $self->locale;
            my $citation = $self->_request(
                {
                    locale  => $locale,
                    style   => $self->conf->{csl}->{styles}->{$s} // $s,
                    content => $csl_json,
                }
            );

            if ($citation) {
                $cite->{$s} = $citation;
                $found = 1;
            }
        }

        return $found ? $cite : undef;
    }
    else {
        return undef;
    }
}

=head1 NAME

LibreCat::Citation::CSL - creates citations via a CSL engine

=head2 SYNOPSIS

    use LibreCat::Citation::CSL;

    my $data = {...};
    my $styles = LibreCat::Citation::CSL->new(all => 1)->create($data);
    # or
    LibreCat::Citation->new(style => 'apa')->creat($data);

=head2 CONFIGURATION

    # config/citation.yml
    prefix:
      _citation:

    engine: {csl|none}

    csl:
      url: 'http://localhost:8085'
      default_style: chicago
      styles:
        - modern-language-association
        - chicago
        - ...
=cut

package LibreCat::Citation;

use Catmandu::Sane;
use Catmandu;
use Catmandu::Util qw(require_package);
use Moo;
use namespace::clean;

extends "LibreCat::Validator::JSONSchema";

has namespace => (
    is       => "ro",
    default  => sub {"validator.citation.errors"},
    init_arg => undef
);

has schema => (
    is      => "ro",
    lazy    => 1,
    default => sub {
        return +{
            '$schema'  => "http://json-schema.org/draft-04/schema#",
            title      => "librecat audit record",
            type       => "object",
            properties => {
                id => {
                    oneOf => [
                        {type => "string",  minLength => 1},
                        {type => "integer", minimum   => 0}
                    ]
                },
                citation => {type => "object",},
            },
            required             => ["id", "citation"],
            additionalProperties => 0
        };
    }
);

has bag => (
    is      => "ro",
    lazy    => 1,
    default => sub {
        Catmandu->store("main")->bag("citation");
    },
    init_arg => undef,
    handles  => "Catmandu::Bag",
);

has citation_engine => (is => "lazy",);

sub _build_citation_engine {
    LibreCat::Citation::CSL->new(all => 1);
}

around "add" => sub {
    my ($orig, $self, $rec) = @_;

    my $citation = $self->citation_engine->create($rec);

    $orig->($self, {_id => $rec->{_id}, citation => $citation});
};

1;

=pod

=head1 NAME

LibreCat::Citation - a wrapper for ciations

=head2 SYNOPSIS

    use LibreCat::Citation;

    my $data = {...};
    LibreCat::Citation->new()->add($data);

=head2 SEE ALSO

L<LibreCat::Hook::add_citation>

=cut
