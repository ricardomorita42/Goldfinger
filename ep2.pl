#!/usr/bin/perl
=begin comment
    *** EP 2 ***
    
    Nomes:	
    	Danilo Novais (NUSP 7990759)
    	Ricardo Mikio Morita (NUSP 5412562)
    	
    Materia:
    	Metodos Formais

    Referencias:
    	http://perldoc.perl.org/Getopt/Long.html
    	
=end comment
=cut

use strict;
use warnings;
use Getopt::Long; # parser de argumentos passados pela linha de comando

########################Declaracao de Variaveis Globais########################

my %variaveis;
my @variaveis;
my @predicados;
my $cnf_text = '';
my $cnfdone = '';

# Variaveis que armazenam os argumentos a partir da linha de comando com
# valores padroes caso nao sejam dados na entrada
my $arq_entrada = 'entrada1';
my $arq_saida = 'saida';
my $cnf = ''; #interpretado como false
my $verbose = ''; #interpretado como true
my $help = 0;

###############################################################################


########################Declaracao de Funcoes##################################

# Nao recebe nenhum argumento. Para cada predicado ele checa quais
# variaveis aparecem, chamando entao atualizaVariaveis(). 
sub substituiValores
{
	foreach my $predicado (@predicados)
	{
		my $predAtual = $predicado->[0];
		my $restricoes = $predicado->[1];
		my @varUsadas;
		
		#my @restricoes = split(/,/, $predicado->[1]);
		
		#Varre o predicado para checar quais variaveis sao necesarias substituir;
		foreach my $var (keys %variaveis) 
		{
			#print "frase: " . $predAtual . " .\n";
			push(@varUsadas,$var) if ($predAtual =~ /$var/); 
			
		}
		#print "Vars usadas: " . "@varUsadas\n";
		atualizaVariaveis($predAtual,$restricoes,@varUsadas);				
	}
}

=begin comment
	Recebe ($predAtual,$restricoes,@varUsadas), sendo:
		$predAtual: string com o predicado a ser processado
		$restricoes: string com as restricoes do predicado
		@varUsadas: quais as variaveis que estao no predicado
		
		Para cada variavel ele troca o nome da variavel pelo valor atual
	dentro da iteracao. A impressao do predicado e feita em substituiValores2,
	que so e chamada quando todas as variaveis foram processadas.
=cut
sub atualizaVariaveis
{	
	my $predicado = shift;
	my $restricao = shift;
	
	unless (@_ == 0)
	{
		#pega uma variavel para processar
		my $atual = shift @_;
		
		for (my $i = $variaveis{$atual}->[0]; $i <= $variaveis{$atual}->[1]; $i++)
		{
			$variaveis{$atual}->[2] = $i;
			atualizaVariaveis($predicado,$restricao,@_);
			if (@_ == 0)
			{
				substituiValores2($predicado,$restricao);
			}
		}
		$variaveis{$atual}->[2] = $variaveis{$atual}->[0];
	}
}

=begin comment
	Recebe ($predicado,$restricao), sendo:
		$predicado: string contendo o predicado
		$restricao: string contendo a restricao
	
	Troca a variavel generica pelo indice adequado e confere se esta
esta dentro da restricao de dominio imposta. Caso esteja, imprime-a
na tela e a salva no arquivo de saida.
=cut
sub substituiValores2
{
	my $predAtual = shift;
    my @restricoes = split(/,/, shift);
    my $pertenceDominio = 1;
		
	#Substitui as variaveis nas clausulas pelos indices das mesmas
	foreach my $variavel (@variaveis)
	{
		$predAtual =~ s/$variavel/$variaveis{$variavel}->[2]/gx;
		
		foreach my $restAtual (@restricoes)
		{
			$restAtual =~ s/$variavel/$variaveis{$variavel}->[2]/gx;
		}
	}
			
	#Prepara as restricoes de dominio para tratamento condicional
	foreach my $restAtual(@restricoes) 
	{
		#Retira os espacos em branco
		$restAtual =~ s/\s//gx;
		
		#Substitui "=" por "==" caso nao seja "!=", "<=" ou ">="
		$restAtual =~ s/=/==/x if ($restAtual !~ m/(!=|<=|>=)/gx);
				
		#Caso uma restricao nao seja satisfeita, nao ira imprimir este predicado
		$pertenceDominio = 0 if (!(eval $restAtual));
	}
	
	#Imprime o predicado caso este satisfaca as restricoes de dominio
	if ($pertenceDominio)
	{
		#Prepara para escrever como CNF
		if ($cnf)
		{
			$cnf_text = $cnf_text . $predAtual . "\n";
		}
		
		#Escreve a formula proposicional no arquivo e na tela
		else
		{
			print SAIDA $predAtual . "\n";
			print $predAtual . "\n";	
		}
	}
}

# Nao recebe nenhum argumento (usa as variaveis globais). Transcreve
# as formula e retorna uma string contendo o resultado no formato CNF.
sub cnfMaker 
{
	my $lit = 0; 		#numero de literais
	my $clauses = 0; 	#numero de clausulas
	my %literals;		#hash armazenando cada literal
	
	my @lines = split /\n/,$cnf_text;
	
	foreach my $line (@lines) 
	{
		while ($line =~ m/([-]?[a-z]+\s*\((\d(,\d)*|(\d,\d)+)\))/gx)
		{
			#print $1. "\n";
			my $word = $1;
			
			#armazena sem o '-'
			if ($word =~ m/^[-](.*)/x)
			{
				if(exists($literals{$1})) {
					#nao faca nada se estiver no hash
				} else {
					$literals{$1} = "".++$lit;	
				}
				#print "negacao:".$1."\n";	
			}
			
			else
			{
				if(exists($literals{$word})) {
					#nao faca nada se estiver no hash
				} else {
					$literals{$word} = "".++$lit;	
				}
				
				#print "afirmacao:".$word."\n";
			}			
		}
		$clauses++;
	}
	
	if ($verbose) 
	{
		print "Convertendo os literais para o formato CNF:\n";
		while( my ($k, $v) = each %literals) 
		{
    		print "variavel: $k | CNF: $v\n";
		}	
	}
	
	print "\nResultado (Salvo em \"$arq_saida\"): \n" if ($verbose); 
	
	#Substituindo as clausulas para o formato CNF
	for my $key (keys %literals) {
		$cnf_text =~ s/\Q$key/\Q$literals{$key}/gx;	
	}
	
	#transcrevendo para o arquivo de saida enquanto imprime na tela
	print "p cnf $lit $clauses\n";
	print SAIDA	"p cnf $lit $clauses\n";
	
	my @cnf = split /\n/, $cnf_text;
	foreach my $line (@cnf)
	{
		print $line . " 0\n";
		print SAIDA $line . " 0\n";
	}
	
}

###############################################################################

####################### Execucao do corpo do programa #########################

# Parseando argumentos a partir da linha de comando
GetOptions(	'cnf' => \$cnf,
			'verbose!' => \$verbose,
			'entrada=s' => \$arq_entrada,
			'saida=s' => \$arq_saida,
			'help|?' => \$help);

if ($help)
{
	print
		"Uso: ep2.pl [-c|-cnf] [-e arq_entrada] [-s arq_saida] [-h|-?] [-v] \n\n".
		"  Le um arquivo de entrada contendo um conjunto de clausulas em LPO sem \n".
		"quantificadores e salva em um arquivo com a instanciacao desta entrada. \n\n".
		"Parametros:\n".
		"	-e <arq_entrada>	Nome do arquivo de entrada \n".
		"	-s <arq_saida>		Nome do arquivo de saida \n".
		"	-cnf,-c			Saida estara no formato CNF\n".
		"	-verbose,-v		Exibe mensagens do que o programa esta fazendo\n".
		"	-noverbose,-nov		Oposto do -verbose(padrao)\n".
		"	-help,-?		Exibe esta mensagem de ajuda\n\n";
		exit;
}

if ($verbose) 
{
	print "Arquivo de entrada: ".$arq_entrada."\n";
	print "Arquivo de saida: ".$arq_saida."\n";	
	print "Saida sera salva no formato CNF. \n" if ($cnf);	
	print "\n============================================================\n\n"
}

# Abrindo handlers de arquivos que sera usados
open ENTRADA,$arq_entrada or die;
open SAIDA,"+>",$arq_saida || die ("ERRO: Criacao Arquivo");

my $i = 0;
$, = " ";

# Processando a entrada
while (<ENTRADA>) {
	#Declaracao de variaveis e armazenamento destas
	#As variaveis podem estar na mesma linha OU NAO
	if ($_ =~ m/^\s*([A-Z]+)\s*:\s*(\d+)\s*(\d+)\s*\.(.*)/x) {
		$variaveis{$1} = [$2,$3,$2];
		
		$_ = $4;
		redo if (defined $_);
	}
	
	# Captura as clausulas e, reprocessa a linha caso haja mais 
	# argumentos na mesma linha
	elsif ($_ =~ m/^(.+\))\s*\.(.*)/x)
	{
		$predicados[$i++][0] .= $1;
		
		$_ = $2;
		if (defined $_ && $_ =~ m/^\s*([A-Z]+.+)(\.|\,)/x)
		{
			redo;
		}
		else
		{
		 	$predicados[$i-1][1] = "1";
		}
	}
	
	elsif ($_ =~ m/^(.+\))/x)
	{
		$predicados[$i][0] .= $1 . " ";
	}
	 
	#Restricao de dominio da clausula que esta em outra linha
	elsif ($_ =~ m/^\s*([A-Z]+.+)(\.|\,)/x)
	{
		$predicados[$i-1][1] .= $1 . ",";
	}
}

# Agora as variaveis estao no hash %variaveis e os predicados estao 
# no array @predicados, sendo que cada celula deste array e composta
# por uma string de clausulas([0]) e uma string de restricoes([1]).
@variaveis = keys %variaveis;

substituiValores();

if ($cnf) 
{
	
	if ($verbose) 
	{
		print "Resultado do processamento antes de passar para CNF:\n\n";
		print $cnf_text;
		print "\n============================================================\n\n";	
	}
	
	$cnfdone = cnfMaker();
	
	print $cnfdone if defined;
	print SAIDA $cnfdone if defined;
}
print "\nProcesso concluido.\n "if ($verbose);

# Fechando file handlers para encerrar o programa
close(ENTRADA) or die $!;
close(SAIDA) or die $!;
