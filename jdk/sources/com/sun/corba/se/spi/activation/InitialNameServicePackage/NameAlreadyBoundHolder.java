package com.sun.corba.se.spi.activation.InitialNameServicePackage;

/**
* com/sun/corba/se/spi/activation/InitialNameServicePackage/NameAlreadyBoundHolder.java .
* Generated by the IDL-to-Java compiler (portable), version "3.2"
* from /HUDSON/workspace/8-2-build-linux-i586/jdk8u202/12319/corba/src/share/classes/com/sun/corba/se/spi/activation/activation.idl
* Saturday, December 15, 2018 12:00:23 PM PST
*/

public final class NameAlreadyBoundHolder implements org.omg.CORBA.portable.Streamable
{
  public com.sun.corba.se.spi.activation.InitialNameServicePackage.NameAlreadyBound value = null;

  public NameAlreadyBoundHolder ()
  {
  }

  public NameAlreadyBoundHolder (com.sun.corba.se.spi.activation.InitialNameServicePackage.NameAlreadyBound initialValue)
  {
    value = initialValue;
  }

  public void _read (org.omg.CORBA.portable.InputStream i)
  {
    value = com.sun.corba.se.spi.activation.InitialNameServicePackage.NameAlreadyBoundHelper.read (i);
  }

  public void _write (org.omg.CORBA.portable.OutputStream o)
  {
    com.sun.corba.se.spi.activation.InitialNameServicePackage.NameAlreadyBoundHelper.write (o, value);
  }

  public org.omg.CORBA.TypeCode _type ()
  {
    return com.sun.corba.se.spi.activation.InitialNameServicePackage.NameAlreadyBoundHelper.type ();
  }

}
