#!/usr/bin/perl
=begin comment
NOSSO CABECALHO
=end comment
=cut

#use strict;
#use warnings;

########################Declaracao de Variaveis Globais########################

my %variaveis;
my @variaveis;
my @predicados;


###############################################################################


########################Declaracao de Funcoes##################################

sub substituiValores
{
	foreach my $predicado (@predicados)
	{
		my $predAtual = $predicado->[0];
		foreach my $variavel (@variaveis)
		{
			while ($predAtual =~ s/$variavel/$variaveis{$variavel}->[2]/x)
			{
				my $a = "O rei bebe cafe";
			}	
		}
		print $predAtual . "\n";
	}
}

sub atualizaVariaveis
{	
	unless (@_ == 0)
	{
		my $atual = shift @_;
		
		for (my $i = $variaveis{$atual}->[0]; $i <= $variaveis{$atual}->[1]; $i++)
		{
			$variaveis{$atual}->[2] = $i;
			atualizaVariaveis(@_);
			if (@_ == 0)
			{
				substituiValores();
			}
		}
	}
}

###############################################################################


open (FILEOUT,">SAIDA") || die ("ERRO: Criacao Arquivo");

my $i = 0;

$, = " ";


while (<>) {
	#Declaracao de variaveis e armazenamento destas
	#As variaveis podem estar na mesma linha OU NAO
	if ($_ =~ m/^\s*([A-Z]+)\s*:\s*(\d+)\s*(\d+)\s*\.(.*)/x) {
		#print $1 . " " . $2 . " " . $3 . "\n";
		$variaveis{$1} = [$2,$3,$2];
		
		$_ = $4;
		#print "S4: $_ \n";
		redo if (defined $_);
	}
	
	# Captura as clausulas e, reprocessa a linha caso haja mais argumentos
	# na mesma linha
	elsif ($_ =~ m/^(.+\))\s*\.(.*)/x)
	{
		#print "dominio: " . $1 . "\n";
		$predicados[$i++][0] .= $1;
		
		$_ = $2;
		if (defined $_ && $_ =~ m/^\s*([A-Z]+.+)(\.|\,)/x)
		{
			redo;
		}
		else
		{
		 	$predicados[$i-1][1] = "";
		}
	}
	
	elsif ($_ =~ m/^(.+\))/x)
	{
		#print "dominio: " . $1 . "\n";
		$predicados[$i][0] .= $1 . " ";
	}
	 
	#Restricao de dominio da clausula que esta em outra linha
	elsif ($_ =~ m/^\s*([A-Z]+.+)(\.|\,)/x)
	{
		#print "restricao: " . $1 . "\n";
		$predicados[$i-1][1] .= $1 . ",";
		
	}

}

# Agora as variaveis estao no hash %variaveis e os predicados estao 
# no array @predicados, sendo que cada celula deste array e composta
# por uma string de clausulas([0]) e uma string de restricoes([1]).

@variaveis = keys %variaveis;
print @variaveis;

print "\n";
#print keys %variaveis;
print $predicados[0][0] . " e aqui as restricoes: " . $predicados[0][1] . "\n";
#print $predicados[1][0] . " e aqui as restricoes: " . $predicados[1][1] . "\n";
#print $predicados[2][0] . " e aqui as restricoes: " . $predicados[2][1] . "\n";






atualizaVariaveis (@variaveis);



close(FILEOUT);


