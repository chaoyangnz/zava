package org.omg.PortableServer;


/**
* org/omg/PortableServer/AdapterActivator.java .
* Generated by the IDL-to-Java compiler (portable), version "3.2"
* from /HUDSON/workspace/8-2-build-linux-i586/jdk8u202/12319/corba/src/share/classes/org/omg/PortableServer/poa.idl
* Saturday, December 15, 2018 12:00:24 PM PST
*/


/**
	 * An adapter activator supplies a POA with the ability 
	 * to create child POAs on demand, as a side-effect of 
	 * receiving a request that names the child POA 
	 * (or one of its children), or when find_POA is called 
	 * with an activate parameter value of TRUE.
	 */
public interface AdapterActivator extends AdapterActivatorOperations, org.omg.CORBA.Object, org.omg.CORBA.portable.IDLEntity 
{
} // interface AdapterActivator