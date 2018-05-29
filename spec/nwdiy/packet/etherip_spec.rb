#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
# EtherIP frame class
#
# [class method]
#
# new -> Nwdiy::Packet::EtherIP
#    (implemented on Nwdiy::Packet)
#    create EtherIP header instance
#
# new(bytes) -> Nwdiy::Packet::EtherIP
#    (implemented on Nwdiy::Packet)
#    create EtherIP header instance with the bytes
#
# new(Hash) -> Nwdiy::Packet::EtherIP
#    (implemented on Nwdiy::Packet)
#    create EtherIP header instance with the fields.
#    you can specify below.
#
#    :data    data (Ethernet header)
#
# [instance methods]
#
# version -> inten
