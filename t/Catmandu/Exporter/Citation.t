use strict;
use warnings FATAL => 'all';
use Catmandu;

# use LibreCat -load => {layer_paths => [qw(t/layer)]};
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = "Catmandu::Exporter::Citation";
    use_ok $pkg;
}
require_ok $pkg;

lives_ok {$pkg->new()} "lives ok";

my $data = {
    _id      => "999",
    citation => {
        apa =>
            "Schindler, S., Miller, G. A., & Kißler, J. (2019). Attending to Eliza: Rapid brain responses reflect competence attribution in virtual social feedback processing. Social Cognitive and Affective Neuroscience, 14(10), 1073-1086. doi:10.1093/scan/nsz07",
        ieee =>
            'S. Schindler, G.A. Miller, and J. Kißler, "Attending to Eliza: Rapid brain responses reflect competence attribution in virtual social feedback processing", Social Cognitive and Affective Neuroscience, vol. 14, 2019, pp. 1073-1086.',
        short =>
            "S. Schindler, G.A. Miller, and J. Kißler, Social Cognitive and Affective Neuroscience, vol. 14, 2019, pp. 1073-1086."
    },
    doi   => "10.419/unibi/124",
    title => "Analysis of data formats",
};

my $data2 = {
    _id      => "888",
    citation => {
        apa =>
            "Maier, G. W., Engels, G., & Steffen, E. (2019). Einleitung. In G. W. Maier, G. Engels, & E. Steffen (Eds.), Springer Reference Psychologie. Handbuch Gestaltung digitaler und vernetzter Arbeitswelten Berlin: Springer. doi:10.1007/978-3-662-52903-4_22-1",
        ieee =>
            "G.W. Maier, G. Engels, and E. Steffen, “Einleitung”, Handbuch Gestaltung digitaler und vernetzter Arbeitswelten, G.W. Maier, G. Engels, and E. Steffen, eds., Springer Reference Psychologie, Berlin: Springer, 2019.",
        short =>
            "Maier GW, Engels G, Steffen E (2019) In: Handbuch Gestaltung digitaler und vernetzter Arbeitswelten. Maier GW, Engels G, Steffen E (Eds); Springer Reference Psychologie. Berlin: Springer.",
    },
    doi   => "10.419/unibi/987",
    title => "Second Test Title",
};

my $host = "http://example.com";

{
    my $word
        = $pkg->new(style => "ieee", file => "t/tmp/test_with_style.docx");

    $word->add($data);
    $word->commit;

    ok -f "t/tmp/test_with_style.docx";
}

{
    my $word = $pkg->new(
        style => "short",
        file  => "t/tmp/test_with_short_style.docx"
    );

    $word->add($data);
    $word->add($data2);
    $word->commit;

    ok -f "t/tmp/test_with_short_style.docx";
}

{
    my $word = $pkg->new(
        style => "apa",
        links => 1,
        host  => $host,
        file  => "t/tmp/test_with_links.docx"
    );

    $word->add($data);
    $word->commit;

    ok -f "t/tmp/test_with_links.docx";
}

{
    my $word = $pkg->new(
        style  => "apa",
        format => "odt",
        file   => "t/tmp/test_other_format.odt"
    );

    $word->add($data);
    $word->commit;

}
ok -f "t/tmp/test_other_format.odt";

END {
    unlink glob "'t/tmp/test*'";
}

done_testing;
