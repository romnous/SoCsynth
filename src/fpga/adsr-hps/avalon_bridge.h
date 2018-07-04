#ifndef _ALTERA_AVALON_BRIDGE_H_
#define _ALTERA_AVALON_BRIDGE_H_

/*
 * This file was automatically generated by the swinfo2header utility.
 * 
 * Created from SOPC Builder system 'soc_system' in
 * file './soc_system.sopcinfo'.
 */

/*
 * This file contains macros for module 'avalon_bridge' and devices
 * connected to the following master:
 *   avalon_master
 * 
 * Do not include this header file and another header file created for a
 * different module or master group at the same time.
 * Doing so may result in duplicate macro names.
 * Instead, use the system header file which has macros with unique names.
 */

/*
 * Macros for device 'audio_subsystem_Audio', class 'altera_up_avalon_audio'
 * The macros are prefixed with 'AUDIO_SUBSYSTEM_AUDIO_'.
 * The prefix is the slave descriptor.
 */
#define AUDIO_SUBSYSTEM_AUDIO_COMPONENT_TYPE altera_up_avalon_audio
#define AUDIO_SUBSYSTEM_AUDIO_COMPONENT_NAME audio_subsystem_Audio
#define AUDIO_SUBSYSTEM_AUDIO_BASE 0x3040
#define AUDIO_SUBSYSTEM_AUDIO_SPAN 16
#define AUDIO_SUBSYSTEM_AUDIO_END 0x304f


#endif /* _ALTERA_AVALON_BRIDGE_H_ */
