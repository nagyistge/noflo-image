noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  UrlToTempFile = require '../components/UrlToTempFile-node.coffee'
else
  UrlToTempFile = require 'noflo-image/components/UrlToTempFile.js'

describe 'UrlToTempFile component', ->
  c = null
  ins = null
  out = null
  error = null
  beforeEach ->
    c = UrlToTempFile.getComponent()
    ins = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    error = noflo.internalSocket.createSocket()
    c.inPorts.url.attach ins
    c.outPorts.tempfile.attach out
    c.outPorts.error.attach error

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.url).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.tempfile).to.be.an 'object'
    it 'should have an error output port', ->
      chai.expect(c.outPorts.error).to.be.an 'object'

  describe 'with file system image', ->
    unless noflo.isBrowser()
      it 'should return path to the fs image itself', (done) ->
        expected = 'spec/test-80x80.jpg'
        out.once 'data', (data) ->
          chai.expect(data).to.be.an 'string'
          chai.expect(data).to.equal expected
          done()
        ins.send expected
      it 'should send an error for zero-sized images', (done) ->
        error.once 'data', (data) ->
          chai.expect(data).to.be.an 'object'
          chai.expect(data.url).to.equal 'spec/empty.jpg'
          done()
        ins.send 'spec/empty.jpg'

  describe 'with remote test image', ->
    url = 'http://1.gravatar.com/avatar/40a5769da6d979c1ebc47cdec887f24a'
    it 'should have the correct group', (done) ->
      out.once 'begingroup', (group) ->
        chai.expect(group).to.equal url
        done()
      ins.beginGroup url
      ins.send url
      ins.endGroup()
    it 'should create a temporary file with a valid path', (done) ->
      error.once 'data', (data) ->
        chai.expect(true).to.equal false
        done()
      out.once 'data', (data) ->
        chai.expect(data).to.be.a 'string'
        chai.expect(data).to.have.length.above 0
        done()
      ins.send url

  describe 'with missing remote image', ->
    return if noflo.isBrowser()
    url = 'http://bergie.iki.fi/files/this-file-doesnt-exist-promo.jpg'
    it 'should do a correct error', (done) ->
      @timeout 0
      error.once 'data', (data) ->
        chai.expect(data.url).to.equal url
        done()
      ins.send url

  describe 'with image that caused deadlock', ->
    return if noflo.isBrowser()
    url = "https://s7.toryburch.com/is/image/ToryBurchLLC/TB_32164_001?$trb_grid_md$"
    it 'should do a correct error', (done) ->
      @timeout 0
      error.once 'data', (data) ->
        console.log JSON.stringify data
        chai.expect(data.url).to.equal url
        done()
      ins.send url
  
  describe 'with data URL image', ->
    return if noflo.isBrowser()
    url = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBhQSEBUUExQWFBQWFxQXFRcYGBUYHBgXFhcVFRQVFRQYHSYfGBokGhUVHy8gIycpLCwsFR4xNTAqNSYrLCkBCQoKDgwOFw8PGikcHBwpKSkpKSkpKSwpKSkpKSwpKSkpKSkpKSkpKSkpLCwsLCkpKSkpKSksKSwsKSwpLCwpLP/AABEIAL4BCQMBIgACEQEDEQH/xAAcAAABBQEBAQAAAAAAAAAAAAAFAQMEBgcCAAj/xABLEAACAQIDBQQHBwAHBgMJAAABAgMAEQQSIQUGMUFREyJhcQcUMoGRobEVI0JSwdHwFlOCktLh8UNiY3KTwoOitBclJjM2RHSys//EABkBAAMBAQEAAAAAAAAAAAAAAAABAgMEBf/EACIRAQEAAgICAwADAQAAAAAAAAABAhESIQMxE0FRBGGBcf/aAAwDAQACEQMRAD8AESEZsurMdQqgsxtxIRQSRqNbc6jPo2VleNjeyyI8bEDiQrgEgXHCtN9GODVcJiMSADK0kozEahYVCogP5bhmt1c1GnxjY/dhsTiApmWCWZWAtlkhLFGXp7IB5G5oVtnKPf2Vdhci6xyMLg2IzKpGhpI5cxsoZiOICOSNSO8oF11BGvStK3Kx5h2BLKGy9nJjHuOQXEOT8r1GwsZg2jtKRGIMmN2VFp+WRopHHvErA+BoHJn4fWxDKQL2ZWU25GzAaaV6MllzJHK6fnSKV0/6iqV+dXf0i4ETbbwsLapIuGVx+Ze2kZ1PgQpB8DVk3n3tOC2lgIC8UOFlTE9sz2RVEaDsrOSAgzWHjmtQOTJI5AwBUgg8CNQfI0tqNb6zYV9oO+ElikSSON5OyZGHa3dWJKEjMQFv5UGoVPRK9Xq9QCV6vGkJqjJSEUqilNIGytIK7rwWiBzanY1pAQK67YUyrq1epozVy0hoLR0muGlpqkNGz0Vpb001dWpGFIRyKU0lep0tGXFIRXbcaSpOOAld2pK6oOoMkeaVF6so+YvWloMqe6s/2LFnxieBJ+ANaHOB2djz0qJ7afQRLKoYnS/z/wAqa+01/MPjT/2RD+Xz1Ne+xYfyfM1f+DV/V39F+myZeH/zcZ8ySKG7vn/4Pf8A/DxX0koFujvm2AEiNEZ4JGzZUKh0cgK9gxCsrAA2uCDfjfRzbe+iSYL1HCYZ8NhyoRzIUv2ZN3SNUZ/a1BYtoCba0OfQnsT/AOlMX/y7Q/8A6S0V3hOX1KQWvi8fgGbxywg3+MYqlYXe1o9kz7P9XdmlGJAlDxBR27uykqTm0DC+nI1zPvhI8WzEOHe+AkieQ9pF972aZO5roTqe9bjQNLVvkbbw4I/7sHzkmFTN98Lh5ds7OhxMKzpNFi0AbgrDs5A/jojD+1VI3o3mbG4xcQkbYdo0iCZ2R+/HIZQSEPs6gEX1FxR3aPpKSXs5fUD67EriKR2jMUZcWcqwbOwPQqD5a0DQfv7u/h8JjFTDRLCjQqxVb2LZ3FzrxsKr1qLb0byevYgTdi0IWMJZmRiSGZie4SLa1D2ZGjyhGWR7/hjAzHwBOnAE6a6UsspjNtMZb0Ziw7PooJr02FdPaUjzGnxovvJtZMMFXDxNA9jdnbv+8C4p6PZ2IERklljeVlchCEzR/dhkNm1DG5JHHhXHf5X5HRPFjrv2rhNc5qjjFGxLEknwFyTyCjUm+lupqTtbBNh2RZCLut7A6qeBDD9eB1rrxy5OezVevXr1G9bFL6wKvQP3pC1MjEDrSjEg0w6JpKWvGkCCvXr1dX8KCc0lq7z+VIZDTBAtIVrxY0lLZmyK9XjXqNg23GkpSKSlQ9SOdKWmsS1lNAnYhuXDmnZug+pq47UA7PXh+1V3cKDuO3VrfAD96N7wS2iby+tLxxeSlT7RnW7dppyFhw5DhUT+kM/5/kv7V1j37tD+xaoyt2eMli23paSvXrRm9S3pCajzYm1K0RILWpp8SBQmfaJqP2xJ1qOa5jsd9cFEMMI48ksTPJicwdbMMket+8bcbE6XqrxMt+NvA/S9X70e7v8ArMpBPcFi+nEcgL89eNc/m5Z60uaxl2exkhkmGJxDRl5V7JkUBhGttGZSbm+huALFtdKrM4hnEYjhVHsFYl3bMR+Mgkka6+49Ks+/YwsWJQQxBgnti5sW5am4/wBKArvy0SNGsMXZOblQNQ2mqyix8r1hPFnbaVzx4wK+0Y4sTG4kKLGwIVI8zWBuQuYZC7agX0XjQzbW05MRO8zgKX0VRwRRoiAnjYfEknnS7SxERkvGrZbDRzfKbcspsbHheh8r2HGvQ8OFxnbG57rvN0NdNi8o1Jt0oVJjTc24V4SM/H+c62pbTDiyTxqThsSRXOF2dnAt8SePkBUs7PCjvHTzPytxpcexKkx7Q01qWkwPCgP8FSIsWVo0oYvS3qPBiw1PZqWiLSV6vGgEr1eJpC1I3Ner1eoBs0lLSXoD1Rse/dqTUHaB4AVOXo57XPdK6YdfG5+Jv+lcbx4wlbaakfLWpezIssSjoAKDbafvAVWE1FZe1ex+pVfL51YvsAeNAcPHnxSD/eHy1/Sr12vhWVm6qQCpKj9s3QV4yN0FasT0jaUMxklSZHY8ajSxXqKqULbjXGa1OYgdKYWE86meOq5pETG+oots/eGXDAmKQpm0bKbXHShQksPAUjQksV5HvKePInh5Ej+zW0wmmdyFcXjZZFMh46kHqDqLf5UBebXU1pUG6p+zu1t7K5+vskBh4jQ/Gs72phgJWA0ALDyANvp9RV8Zj6RMto5l0/Wos85YWvXbtyFNmIg1IcYaAk2t/OVWnY+7GbWTugWJ4Mf7v71xu9IYSWygtpl1GjHQacT8aKyTyFTmJjOpJzXYnnoPZHAVc1od0ztG0ICxPYX/AC292g4++hWKd2PeLHpe3DoNaiYzEXkHeZuRuSfqTU2UggaG/Cj2J1UYn5edNOvgalFOpI+A+lMOg43qabvBzlWtfSjCPVfYVJwWKsbEmkBuvGmkcdacqVRy1JXRrmgy2rk169ITTBu9eNepGpAtRETPOq9WH1FSQ1e2CmbEg9Ln9B9ajL0rFdUNlqsbVkvIfCrPObLVOx0urHzrX6F9k3aTNiS35VY+82A+tWyq7uhFpI3Ugfr+1Hu1qPH91ewNmpsy1YZsGoHAUOeLXQD4VzXzz8VP49/Qs66moWJmubcB4ED6UZxOFJBA4mghhckgqwtxPL/StvF5Mcmfk8eWKIzknX5muEU3sNfIj6UQbZy2uzZfcCT5D9TXEcAXXJZfzObX+YHwvW/tlvRgQXOXgTwDXW/Gpeyu66B7nK4sV/Cp0ILWt1NteBpyEm+hW35VzkeRABDCpOFIjxMZKWubsPLW63AufhVyItbxsjYw9S7MfiQ+V2H01rAt6N35IFs6lX1zHT8OWw9+YfCvpjZsYEKAcMq28raWrIfTDOGxix6C0YJPvLHzvYWP+6aW97ROmaQ7Da2o100vwvy8TXf2aTofa6ai3n0qS2OfLmBsFtmJa3Hhy6/pTc7llJJ87EEe/n8aepIqWorYWRRmDXAPXgfECmptpOyFL87n3cr05ICehv0/ypoYU35Dof3qf+LlRsI+VuGvj+lF0vx0NQvVrHXiPD+fGimGTu+XkeP886IVcuAQeAHhy8wdagOPCiEqX4Em3852tUCc301/ngKLBDRbTiKZDa8adA0PA02yUjFsOpKg08Eboal7IXuDmKKLHasbl22mHQGubofhTio35TRgp7q92dLkqeOBIgbpSNA3Si+nMV7IKfKn8cAipri1WH1delNPs9TRyLgAymwNTNz4ru7eAHzvUifYwI0Nqk7DgEAIJJub3t4WtalvdgmFgltCSyGqZj27tWnas4ZDlN6qO0r6CtMrNJ12sW7yZMKD1zN+30od9oNRiRcmFC9FUfSgeUeNGPULKrpiIyelC3iN+BqzGMH/AErk4UdK87Lxbd2Pk0rPDlfz4e+uXXNx/QAeNqskmDXpQ3H4XoNKm4XGK5y0FksoJAAPXn/lVbx6kyZmOpNgOZ52BPDzq0OmtAtuwllJ5DT9zV+DO8u2fnwnFGwuJLSLGCveKhQpGS7Wta3tcbXPOjuI2SjYhMOWyOQCslrDtCMyrkX8JIIvfmKpkOlyDr/DVj2fvFI2W0PaSgZUIQyOL8cltRx6G169bG/ryssb9N/3B236zgYyVyumaJ1vezRHIdefD51RPTDs4PjIBa2ZCSxHEI2tm8Li48RVh9Emz5YsK3bI6NJIzhXUq1iF1KkXFzfjRD0ibAknijkhXPJCXOTTvqy2YA9dAbeFT9nGawtOj4f1cFogiqFBsiyE/ePKqmxNifauCDTW9HZu7BMq2YsSthfuhb2v1+hodLhMTdh2fZ5bZi5CC/QXFibcuVRJIW1LG/G+o18a1t2jjJQtlykkAG/Lhfz6GuHkHIEA8Ofx1qTPh3PK466UwI7aZbHjof4LVFaQ3e/uojhIu7obH60kOx2YXym3I8CfA9fdT5j7ul1I8uPT4USdlQ3GRFeFvp79bUOOa/eIPuo1i4O7ybrawt56mx+WtDYo7i2ngf36UZQ4YWPS4pxRcdOnS/6U+kGnTkTy/wAq5XBlW53H858anS7raxbDTuW6UXEdc7C2c7xhlQkddBRUbNk/If70f+KsMsa6JlNBrR0nZ1POz3twA85IR/300+H6vEvnNB/jpcaOeP6hGP317s/CpDZOcuH0/wCPD/ipF7M//cYb/rKfpRxo54/qOye6lDnz9360/kj/AK6DTo5P0WueyT+uj9wlP0Snwo54mu08KTQ9Ke7OP+tHuinP/bSMsX9a3uw8/wCtOYUucMuopt8Mp4gU+ZIxezSH/wABh9WFNS4yMa5MQ/Syqg957xFHCj5MTeIjLCxOnj+9RvUE603iduEaJAieMmaQ/MgfKo/25L/wv7iftVcbPtFzxXZt78KP9n/53/ao/wDTDDf1R/6jVSGCnn8q4aJepqP8Tv8Ate/6aYf+q+Lt+9Qdob3wspCxKPe/6PVLkh6E/Ko0gt1pf4N39EsXtBma6mw6D/Oocrs+ly3xqEX15/GnIZGJsNBrc35eJ6Cokm+o15X1s9hsAtwGtpyFyb+QvWveiZoxI4EYVwoBOt/LXgfcPKsv2fIB7F1X8T8GbS5CfkFuJ4/IVZNkbRaMhlJTKQFsOftPccwALnqSoJ1N+nG7cuUbxLKEIJNgdL9D49K6THKzALqazuf0nsFy9mC66Mbm1+YtxOv0NVlvSnNFMxSKNQRYoAdSL63HW/yp6lGtRofpJ3dfFYUiNmDJdgqhbv8A7tz8aoG4+6gKGSdAST93mHAcMxQgWa9+IvpRTZPpInmD9oEAFvZvcKfPncUdw21lsAeJcLfx4/A1rhgyyy+nhhGjtcAjyHwGlCtr4OJrkxpfwHHwtyontHaws4J0sR+mnz+FUHae8dmNmuOHvHQ8+dadRM7dNiFU2HdXkeK+R6a6a0MxJUE8BfqDbToQeVDNo41b5hcA8LH8XOx4a2JoVPjTbXNa/wDDUXKNNCOLcWuFB14rb4Cx+tMlCx8xcaW+NRMFhGdvD83IjkaPtgCseYtccP8AWlrZ+kCOEhb2OmhH6jqKkQxlhbjbqOVr8alJw0OYGxN+utwOlOsygG3QX9304GnqQtoMmLy6ZVJHVQfmQaZO0W/Kn9xP8NEo8PmJvXX2d0tXPlvfTWa+wv7WcDgv91P2pV2tJbiB7l/apsuz+qih80eU2pdi6+inacvX9K8dpy/nb4mm64egbK+0Jfzt8T+9J6/J+ZviaaY0l6DlPw4pyfaPxNPvM2Yam1xfWo+F4mnpDrQY+Y7rxoHPKyyGxNGcPN3fdQbHn7y/hTnoqmYHFs1wTfTnrUnJ4D4D9qG7Jl7/ALjRa9M4puIiIdrHmaRZ3HM0em2cMxJ61yNmjpWMLYKMe3Ox91c+t+FHRs8V77NXpVapbAVdSa7y6Zb8dWPhyH85mjf2ctRsVs9b2PDUsfAfz4kUtWK3tGGJK8hqL+AS/dHvPePWwq9bB2MrvGjG7JYG1/asskxJ5XZlH/h1QsMA8y3/ABSIDrpYkC3lW4ejnBgxGQjvMzsf7TFhfxtV4TdLLqBeJ3IRVLZzmIvrrrx4H+a1Qcfs9Uka/Lmb6n+Ct+2lh17M2HKsm2hsB5JyEXNzYDn/AK/pWsxm9ouW5pVNn4xo2PxtzOWxA6cR/wCarhDjfvAl9AAPIrd7+PMe6g025eLGaTsWLfeMBpxt3QQOAuBUeFJFm9kgrkvm5DS5+taS6Z2bFtubWFmJvrljPkxChvINqfAVRMZKczcb3Fx0tcG3Tp8Km47FF5dT3WBW3uI92ovSrDmY9TbXqe7e/vU0W7onQbbuFeWrD48R+tcwYfMVX8w+FTHjsoa3BrEeBBX4XB+NG8DhwiFrDW5HW3y+tTVCezdlpkEYsGtoTxv0vxog25EjA962nXiTaxHTgahbHlMkqqCCfdcW4nyrRsLg7AFgW8b2Hw+FaSzTO+1Nh9HJWMN2uptcchwt+tR8TuWU1L+B4e4+NaFicKFHDKTw6Hwqs7Y2mAtgLnnRZNDdVY7P7PneuitdyuDra1Mk1ko1Kar+0T3/AIUexAqvY8/eH3VOSsfZkGvHhTYNJJMAKhbzGuGNNtMTXBajRiGCGlLiiQDXsIO6KTFNS0ILYV+6PIVExcRY3tUjAvdR7q80+VrEaGlF2RC2fGVk16Gi9RzIpNhxqTkplIlSbO72t65+zvOjc8eulMtFenMWHMLXZ4I4H5V39mjp86JmEAU3lvT4jmgfZ46D41HxOzVPIa+fuo32FqZnjFHAudADsoAgqqixB0HQg1bdhYvFwRERlbEC4OvDjb3UM7o5j40YwW1Y1Fiy/EU5NU+Vots/bmJm7kuUKeFuPx6VaNm7KCgkWufmfG9UP7eiWRTe452F6teE34wtmvIFK20Oh16CtCHGDDTQ+Yqmb6YKTEApFlU3Ba+l7cBcCjGI34wrHuyqWA62+tTdmBHAdbNmFw3nRKLtkMvo2xRKG6XWx/Frx0vbqb3p191pkIDoba3K8jdjpztqprapbD3WpnEQqSAwHHT4U5orti39HXGsi5bm5HUnU6dCdaY2jGAvDwFW3fLEdmWVdWW2h6HpaqHi9ssTZlUdeP70ZibGNwsWiT5nI1GUA+NbNLMgsMwPDmOHG56VgGzCpa5ZVB53A+tGsSkea8c4F+OV/qVOtE9Hqba/tYqEF2HOxJFUDarZmOnv60Axm1QiKrYh3AHC7HXlQrEbzrcd5yBa/H9TT312m/0PstcEUCO9cY4I5/uj9abffAcoz72H6Co3FDE61VdqP963u+gp+bepjwRR7yaET44sxY2udamqxunbPXDNpTDYnxptsR41NXtIDUuaoTYodfnXBxY60t0bWOLEKB7Q+IqPicWp5igRxgrj1zz+VHYlWrBbXjRRmPDwNJPt5CdAx6cP3qptjDSeuHpSG6sf2grNmGhv4U/9on+Gqp6ya9603WjZ9tEn3vk5Bfgf3qMd5puqj+yP1quHEeNIcUOtDO6/BmfeSdj7Rt5L+1Mttuc/7Rvjb6UIOLXrTZxq+FBb/odk2s/ORj/ab96g4nHlvxE+80NbaAFN+tino938Tc96mQ40j+Gg4xduYpPX6Woe6s2F24QRcZvfajcO8EbXzIAT4/ras8baB6mkG0mqpdF3V9xm24uCgfP60V2dvli40AR1IA7vdB8hxrKzjWqRDt2dRZHI8gP2quUElbF/7Vp+zAMQMnNixAvf8tuludTcZ6TXeMARZJLaa3APM3tWHybVxDcZH+NvpTLzyn2mc+bN+9HySK41at5NuyTSFpHLMfd8qr74i3P5ih/Yt0Ndx4Qnwqcs4OCcMePCnRtgDh7uNQPs49RSps7WxNL5JD+NOfbt+p/njUV9qeB+NefZwAvc6U5gtl9o4RVLMb2A4m1K+XavisRDtA0hxzVa8L6OMU+oht/zsB+9E4fRHiDx7JPeW/SnN36TqM/OLY0hkbqa0keiSRfanT3IfqWqiYiLK7re+VnW/wDysRf5VOVuPtWOMyQO8etIYjUg1yoqeS/jhgwkV3h4Mxtw406w0qbu5s/tZSL2Fr05bU3GSorbPtzpBhRfrV1fdmMC5JPvqtvge8elzb9KVmSppA9WXpU3CbFeQArHfxtTUkVjatN3Sgy4SO+hKk/Ek/Sn45zuk53iz6fYsqtYx20rn7Ik/JVs3q2yYsSFsGXKCeouTwPuFDv6UJ/Vt8R+1GUwxutnLkq+B3fxOIDGHDzShPaKIzAcNCVHHXhxps7DxPZdr2EwhtftTG+Sx0B7S1reN6+idysEcHsTFBSO0ibHsGAtdkzZWt/ZHwr2MzYndiPtGJaaHDB2FgSZJIwxtwv3r1TN89bN3YxOIJEEEsxGh7NGYDS9mIFgbdabn2LNG2SSN0fT7t1ZXObRbIwubnQda+jNj7Llj3djjwciwTtEjLIxCDO8gZ2ZrHUgkX8aF+meJZMNhJIXj9ZjmurBlJGWGSZuF9M0KmxFrgUuxtne9PodnwWDGJaVJBdMyKj3UMLlmJ4Bed6j4ndHBLswYhfX/WOyja7QMMPmYrm+97O2TU2ObXSti9Kc87bHUQljJOYo2Ay3dZEPaLqLC4v8Kg7bjP8AQ9QAS3qmFFra3zRC1utMmaR+hvEHZ3rucH7vtOw7OTtDrYLbqRrwqrYDYDTtlgilmawNo0ZzY8Cco0Hia+gIdtzruv6znIxC4YnPZbhlOX2bW4C3Chno3w/q+7M00XdlKYyTOLXzR9oiEnmQEFLWz3piO09hvAcs0MsLa2EiMl7cStxZh4i41FX5fRLhodlpjMXJiu0kQMI4Yr5CyF1WQZSQABqxsKum+mEGL3Zw8k/fkMeAfObZs8hiR2BtoSHb40Q2rteY7tJP2h7Z8NhyzgLc9p2avoRbUE8udEmjt2zzd/0VwHZa43FviVLC4igiBYDNlW6srM1/auLCx99UnZ2yJ5oy8UEsqp7bRxswU6HUqONiDYa61vOz9rzLuy84kPbJh5ir2W47MsqaWymwAHCoG6DNht1pXiOWSOPHOrAC4ZXlytw4iw+FFmxMrGKSYCZYhKYJhEQpEhikCENYKQ5W1iSLa63pzZ+xsRib9hh5ZsvtdmjMAdDYsNAdRpe+tbPvpOW3WjdjdmjwDMdBcmSEk2FE8Ds6VN38MmDkSGUx4Zs7EILsyPMWYg6tdvMtU8Id8lYGm7794OGjkW14nR1k72iAIdTckAWBvVp3i9E0uBhSeWVHjZsrZEcGO8buHcm9luoXzcVcfTm6dng8RBInrEU4AdWRioCmXhrcBowQDp8aP+lmZzs+CMOVWeVY5rZbunq88hXUG12jXhrVaid1kW1N3MLHs5Z0O0BOVgJ7WArBdygk+97MDLZmy97XTjR3Zvo3lgwK4yURyKyxOYjHJ2kYdlDX0PANc6cquu9MAl3Xw6nQSRbMU26M+HGl/OpWN2xiG3ajnWQjESQ4f7yy6mRkU3BFhcMRw50SQbqrwrh7hY4jKxAOWKJ5Tlb2WcIpyAjhmI4HoaquC2emF2nezxIEkkyyI8bKLHMMrqCQDwYXHwrRd24nwu7E0ynLOYcTKzjj2gzKpvzyhVUeCipnpBwom2Rh5HJ7TNhO+LZgZikcliQeIc8ulO9jYTtrDSwbNGKkxE8Ujxl0jhgRljYoXRZi6MwUADMxK8+FPvHKdnDGzT4iHMCUhggRmAuQhcSIzEm1ydBY++i28uJkl2FCTIwbErgopWGW5TEvFFNxFgSsjcudOHGS/YIftW7UoidpZM1jMIr2y5b5TbhVcqSuLtoGJTllkISMytHDLIqsyKxzMikA63I5X1tWY4nBWHatBIsbm6yNFKqN2hupEhUKQb6a63rYNnqcFuxIYGKtFHi8jaZgRPKAx0sTbwqN6Upyd3IXPEjAseAF7KT4DWlbv2cumV4HYrz3MGGlmAvcxxuygjiC4Fr+F71Enw+Vuz7JhLcDsyjh7twHZ2zfKt6XZ0sexsImEkWFwuDJdmCAr3HluSNWbXzvVX9NU6JJgcVh5VWdJXQMhjYgZcykg3BsQQLj8R60tQ+VUvfb0YzbPw4mkeORWJU9msgydxmDOTfu3AF9PapcXsHCYOBJoDtASM0Ift8OUiKsRns5jHU2sddONaH6fca8ezY1Riqyy5JALd5RE8gBuNO8inTpTvpZH/uBP+bB/VaC3VV2runio9npjGCkFYmeILL2iCTLmzC2hQMSdPwmqPgsBLObQRSTEcezRntcXGYgWW46mtl3p27P/RqLECQiaWHCZ3stz2xjWTS1hcO3LnUXYSHCbpmWElJDh5Js4453JOa/UCwHgBT2cumIbSwckTlJY5I35I6MrG+gsrDXXStX21u22C2Yk8mIn7UxApHFChjVuzzASEozqgGjMWHPhwox6Z8OG2RBiP8AbRSYd0fS4ZrX91ze3gKLb/Tu+xU77AzjDRykZbss2VZBqCBcE8udTjNXordqPtjcOJtnrjsXJilkkS6xQxA5CVZ0WQFGYAAd5iQL9LgVl3YN+Vf75/at/wBt7ZmO7KYgSMJngw2Z7Lc9oyK+hFtQxHDnWF+pjx+Jp2b9nNtj2Hvxg2weLikabspWxBEqQTuCkwJfVUOVlJYENbgDRftIhu/h+yL9llwYQvbNl7eIKWtpc+FY/un6R8Xs+MxRdnJCzFjHKpIBb2srKQQDzBuKXej0j4vHRiGTs4oQQeziUgHKQUzMSSQCLgCwv1tS2ON3pqmK2e2O3fkwUGVsRGFiZCyizRSq4uTwugDA87ioW9G6+FhGFiw+HhXFKsjTGNFDdmMLNGczAX70roAOZueRrFUxDqbq7KeF1ZlNuhIN7eFTsBvHiYb9lO6ZjdvZYserM4JOmmpqecV8db1vFjBJsrD4iMCZIhDM4VkF0WJg5GYgXGbh4Uy8qtu7hujJs/TwM0FYmN65TfPHh5M1y2eJe9fjfJlBPjap+G33VcubA4dstiti62Km4sNQLEC3lT54l8dbDg4O32JJBFZpAZo8lwpzJO11OewGg56G9QNzMQMXsbFYaIZZWGLKRsVBCYoyywNobFSJAMw0urDkazyb0l4NnLzYK7m2ZhlJNuFzoT76sWz9v4LELGFgYBBlj7qgougyqytcDQaeFXO02aWbb2HKbHwez3sMQy4NGS9yBh+yed7i/dUJbNwuyjmKbnQPuvhkv7UGCXl+Joh/PKkwOCiXM0aBWNgzcWIHAFiSSBfhemBsHDqRaFBlKkacCpupA8DrVcU7Skw9t2Z4gbkRYpB1JEkii9qD7D3hwsOycRgcU0yqPW42ljhmkUrIzlmV1UqCpZlIa1inSpx2FhySexS5NzpxZiWJIvxvc1IwsmIhzrBJH2Tu7PDNFnXM/t5GVlIDNdiGzasTpSuOjNb2Ir7swrCGyOuz1iDWzZTLCEBtpmt0rnGYF9pbtrhcOFOIVMPFJGzBSjwvHnDX4aKSDzBBF7iu8QZ5yvrMqskbZkhij7OPML5Ge7MzlbmwuFBsctwKal2REzZigzEWLC6kgcAWUgkC540TG0K/6YdlYLDRQRYaCGPEjM8nZIoYIInUZ8ovZnIsDxyk8qsXpfwbYzYsUmHZXWIpiGZWUfdrBKCy666uNBXEOyoowcq5cxuba3NrXYnVjbr0qHJuxh2veNbG5IyixJ1JIGhuTT4UtjG8TgbuYW5Asuy76jS0uHvXezcK0+7cEUWVpEiguoZR3oZEZ0JJsD3CNarWJ3LgdQpQZRwALgacNA1q4TdaJOCjxJJJOltW4nTrejjT3B7dbFevbvT4eEffGLEIIyQD97meEknSzI6G/C5Ivoanb8TBcBhcISBOxw5KjUhcPleVjbgvdC5uriqk2zYxbuAZVygrdSFHBQwsbeF6XZuzFWQtqS2mpJOoAN2OpGg0PClxoWva7j7Bweo9rZfP/jwV00g/o+vXuf8AqloLDsKBSLRJ3SpXTgVsVIHgQDStsOD+qTjm4fivmB882vnVcCcYbebCfZWJweKeZFDYtTKkMrqUknkkDJIEK3XNkINrFW6VJ9JQV93IAoIRvUcoaxIVglg1tLgHl0qL9tYjBRSLC0bwXkkMMyFgC7F3COrCylmZrMG1Y2twqmbxb6YrHZVmZFjU5lijXIuaxAZiSSxAJtyF+FRYbQ9pYNtq7v4eLDZHkthQ6llGVoiqyqxPAix87eNVX0x4HBYfsYsLBDHMnaSS9mqKQmUqiuV11Y3AP5DVOVbElSyE2uUZkJtwuVIJ99ciEfHUm5JJ6knUnzp6DW/TbhGxOy0lhyukTGVyGX2DDIgYXPe1caDWnPSq4OwYxf8AFg/qtY42HULl1C/lBOX+6NPlTbxeLW6ZmI04d0mwp8aGyYvZ7YzdfDxQZXcQYMkZlXWExtIpJ4MMp0PMU3uw3r+6xw+Hs0wgaHJcAh19kNfRbgqQTyYVjXZ2vYkeRK3PjYi/vr0ZKHuMyGwF1ZkNhwBKkaeFLhQ1304bTRNlRYQkGZjGSoNyqxKWZyByzBV/tUR9JGLybBhZTqpwJHDqlYt2VySbkniWJYnzY6mvdlcWJa3S7EaeBNHGhr+1mH9EoR/wMH/+8VZJmHSmGwmlszZR+HM1hbhZb26U3Zvzt8BS0udP/9k='
    it 'should create a temporary file with a valid path', (done) ->
      @timeout 15000
      out.on 'data', (data) ->
        chai.expect(data).to.be.a 'string'
        chai.expect(data).to.have.length.above 0
        done()
      error.on 'data', (error) -> done(error)
      ins.send url

  describe 'without data in a data URL image', ->
    return if noflo.isBrowser()
    url = 'data:image/jpeg;base64'
    it 'should return an error', (done) ->
      @timeout 15000
      out.on 'data', (data) -> done(data)
      error.on 'data', (error) ->
        chai.expect(error).to.be.an 'object'
        done()
      ins.send url

  describe 'with unsupported protocols', ->
    return if noflo.isBrowser()
    url = 'chrome-search://foo'
    it 'should do a correct error', (done) ->
      @timeout 0
      error.once 'data', (data) ->
        err = new Error "Images with chrome-search: protocol not allowed"
        chai.expect(data).to.be.eql err
        done()
      ins.send url
