class trust_fact_test{
  notify{'tft':
    message => "This is the fact test message : ${serverversion}",
  }
  notify{'tft2':
    message => "This is the 2 fact test message : ${servername}",
  }
  notify{'tft3':
    message => "This is the 3 fact test message : ${serverip}",
  }
  notify{'tft4':
    message => "This is the 4 fact test message : ${server_facts}",
  }
}
