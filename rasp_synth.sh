#!/bin/bash
#Controles para RaspSynth

#Constantes
#Nome do dispositivo conectado que atua como controlador midi (teclado controlador)
#Para descobrir o nome, conecte o dispositivo via USB e execute o comando "aconnect -l"
declare CONTROLADOR_MIDI_1="JUNO-DS"

#controlador midi virtual (necessário instalação)
#"Virtual Keyboard"
#declare CONTROLADOR_MIDI_1="Virtual"

function iniciar_jack_server() {
	jackd -d alsa & 
	echo "=== JACK INICIADO ==="
	sleep 2
}

#Configura conexões do ALSA (Teclado/dispositivo > Software)
#O teclado precisa estar conectado antes de executar o script
function configurar_alsa_aeolus() {
	aconnect $CONTROLADOR_MIDI_1:0 'aeolus':0
	echo "=== CONEXÕES DO ALSA CRIADAS ==="
	aconnect -l
}

#Configura conexões do ALSA (Teclado/dispositivo > Software)
#O teclado precisa estar conectado antes de executar o script
#No Setup do Qsynth, alterar MIDI client name ID de "Pid" para "qsynth"
function configurar_alsa_fluidsynth() {
	aconnect $CONTROLADOR_MIDI_1:0 'FLUID':0
	echo "=== CONEXÕES DO ALSA CRIADAS ==="
	aconnect -l
}

function iniciar_aeolus() {
	iniciar_jack_server
	aeolus -I Aeolus -S /usr/share/aeolus/stops &
	echo "=== AEOLUS INICIADO ==="
	sleep 2
	#Configura conexões de áudio
	jack_connect aeolus:out.L system:playback_1
	jack_connect aeolus:out.R system:playback_2
	echo "=== CONEXÕES DE ÁUDIO CRIADAS ==="
	sleep 2
	configurar_alsa_aeolus
}

function iniciar_fluidsynth() {
	iniciar_jack_server
	#Inicia o gerenciador gráfico do fluidsynth	
	qsynth &
	echo "=== QSYNTH INICIADO ==="
	sleep 2
	#Configura conexões de áudio
	jack_connect qsynth:left system:playback_1
	jack_connect qsynth:right system:playback_2
	echo "=== CONEXÕES DE ÁUDIO CRIADAS ==="
	sleep 2
	configurar_alsa_fluidsynth
}

function ativar_somente_aeolus() {
	#Remove todas as conexões
	aconnect -x	
	configurar_alsa_aeolus
}

function ativar_somente_fluidsynth() {
	#Remove todas as conexões
	aconnect -x	
	configurar_alsa_fluidsynth
}

function ativar_todos() {
	#Remove todas as conexões
	aconnect -x
	configurar_alsa_aeolus
	configurar_alsa_fluidsynth
}


function diminuir_volume() {
	#No Ubuntu
	#amixer set Master 3-
	#No raspberry
	amixer set PCM 300-
}

function aumentar_volume() {
	#No Ubuntu
	#amixer set Master 3+
	#No raspberry
	amixer set PCM 300+
}

#funções precisam ser exportadas para serem visíveis pelo app yad
export -f diminuir_volume
export -f aumentar_volume
export -f iniciar_jack_server
export -f configurar_alsa_aeolus
export -f configurar_alsa_fluidsynth
export -f iniciar_aeolus
export -f iniciar_fluidsynth
export -f ativar_somente_aeolus
export -f ativar_somente_fluidsynth
export -f ativar_todos
#Variáveis que precisam ser exportadas para serem visíveis nas funções chamadas pelo app yad
export CONTROLADOR_MIDI_1

yad --form --title="YAD - RaspSynth" --width=300 \
--field="<b>Inicialização</b>":LBL '' \
--field="Iniciar Aeolus":FBTN "bash -c iniciar_aeolus" \
--field="Iniciar FluidSynth":FBTN "bash -c iniciar_fluidsynth" \
--field="<b>Ativos</b>":LBL '' \
--field="Somente Aeolus":FBTN "bash -c ativar_somente_aeolus" \
--field="Somente FluidSynth":FBTN "bash -c ativar_somente_fluidsynth" \
--field="Todos":FBTN "bash -c ativar_todos" \
--field="<b>Volume</b>":LBL '' \
--field="Menos 3":FBTN "bash -c diminuir_volume" \
--field="Mais 3":FBTN "bash -c aumentar_volume" \
--button=gtk-cancel:0 \