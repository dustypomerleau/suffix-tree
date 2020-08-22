defmodule SuffixTree.Sample do
  def sample() do
    %SuffixTree{
      id: "WqFqgrpY2xPtZjoVhYnbgQ",
      current: %{
        node: "root",
        index: 0,
        explicit: nil,
        phase: 0,
        extension: 0
      },
      nodes: %{
        # nd (nd)
        "4rQYWUSp2K7Ld0A6ykFmlA" => %SuffixTree.Node{
          children: [],
          id: "4rQYWUSp2K7Ld0A6ykFmlA",
          label: {119_986_673_794_530_177_314_783_485_916_755_773_721, 1..-1},
          leaves: [{119_986_673_794_530_177_314_783_485_916_755_773_721, 1}],
          link: nil,
          parent: "root"
        },
        # d (bad)
        "5O5iub3q8JeRLmGWAoKX9g" => %SuffixTree.Node{
          children: [],
          id: "5O5iub3q8JeRLmGWAoKX9g",
          label: {281_258_601_728_791_563_064_168_111_435_194_686_092, 2..-1},
          leaves: [{281_258_601_728_791_563_064_168_111_435_194_686_092, 0}],
          link: "9npec939_hLfb3HGppTKeA",
          parent: "Uc_mQT4WqQ28NITsS0h09Q"
        },
        # g (bag)
        "9N-Q5Ty2Toxzo7916kkFTw" => %SuffixTree.Node{
          children: [],
          id: "9N-Q5Ty2Toxzo7916kkFTw",
          label: {242_629_559_588_796_728_772_605_389_698_047_948_072, 2..-1},
          leaves: [{242_629_559_588_796_728_772_605_389_698_047_948_072, 0}],
          link: "L-np9X_0sE0RDqpjrYvU-A",
          parent: "Uc_mQT4WqQ28NITsS0h09Q"
        },
        # d (ad)
        "9npec939_hLfb3HGppTKeA" => %SuffixTree.Node{
          children: [],
          id: "9npec939_hLfb3HGppTKeA",
          label: {281_258_601_728_791_563_064_168_111_435_194_686_092, 2..-1},
          leaves: [{281_258_601_728_791_563_064_168_111_435_194_686_092, 1}],
          link: "iXcCzLfHOB7S2Eo-txir_Q",
          parent: "B1VB74WCJfgqQTCYn8g_Qg"
        },
        # a
        "B1VB74WCJfgqQTCYn8g_Qg" => %SuffixTree.Node{
          children: [
            "9npec939_hLfb3HGppTKeA",
            "L-np9X_0sE0RDqpjrYvU-A",
            "LJmmeFb6FnYCkRM-D2sqww"
          ],
          id: "B1VB74WCJfgqQTCYn8g_Qg",
          label: {242_629_559_588_796_728_772_605_389_698_047_948_072, 1..1},
          leaves: nil,
          link: nil,
          parent: "root"
        },
        # g (ag)
        "L-np9X_0sE0RDqpjrYvU-A" => %SuffixTree.Node{
          children: [],
          id: "L-np9X_0sE0RDqpjrYvU-A",
          label: {242_629_559_588_796_728_772_605_389_698_047_948_072, 2..-1},
          leaves: [{242_629_559_588_796_728_772_605_389_698_047_948_072, 1}],
          link: "qriCOXxgMBwOXEzfc7e1Gg",
          parent: "B1VB74WCJfgqQTCYn8g_Qg"
        },
        # nd (and)
        "LJmmeFb6FnYCkRM-D2sqww" => %SuffixTree.Node{
          children: [],
          id: "LJmmeFb6FnYCkRM-D2sqww",
          label: {119_986_673_794_530_177_314_783_485_916_755_773_721, 1..-1},
          leaves: [{119_986_673_794_530_177_314_783_485_916_755_773_721, 0}],
          link: "4rQYWUSp2K7Ld0A6ykFmlA",
          parent: "B1VB74WCJfgqQTCYn8g_Qg"
        },
        # ba
        "Uc_mQT4WqQ28NITsS0h09Q" => %SuffixTree.Node{
          children: [
            "5O5iub3q8JeRLmGWAoKX9g",
            "9N-Q5Ty2Toxzo7916kkFTw"
          ],
          id: "Uc_mQT4WqQ28NITsS0h09Q",
          label: {242_629_559_588_796_728_772_605_389_698_047_948_072, 0..1},
          leaves: nil,
          link: "B1VB74WCJfgqQTCYn8g_Qg",
          parent: "root"
        },
        # d (d)
        "iXcCzLfHOB7S2Eo-txir_Q" => %SuffixTree.Node{
          children: [],
          id: "iXcCzLfHOB7S2Eo-txir_Q",
          label: {281_258_601_728_791_563_064_168_111_435_194_686_092, 2..-1},
          leaves: [{281_258_601_728_791_563_064_168_111_435_194_686_092, 2}],
          link: nil,
          parent: "root"
        },
        # g (g)
        "qriCOXxgMBwOXEzfc7e1Gg" => %SuffixTree.Node{
          children: [],
          id: "qriCOXxgMBwOXEzfc7e1Gg",
          label: {242_629_559_588_796_728_772_605_389_698_047_948_072, 2..-1},
          leaves: [{242_629_559_588_796_728_772_605_389_698_047_948_072, 2}],
          link: nil,
          parent: "root"
        },
        "root" => %SuffixTree.Node{
          children: [
            "4rQYWUSp2K7Ld0A6ykFmlA",
            "B1VB74WCJfgqQTCYn8g_Qg",
            "iXcCzLfHOB7S2Eo-txir_Q",
            "qriCOXxgMBwOXEzfc7e1Gg",
            "Uc_mQT4WqQ28NITsS0h09Q"
          ],
          id: "root",
          label: nil,
          leaves: nil,
          link: nil,
          parent: nil
        }
      },
      strings: %{
        119_986_673_794_530_177_314_783_485_916_755_773_721 => "and",
        242_629_559_588_796_728_772_605_389_698_047_948_072 => "bag",
        281_258_601_728_791_563_064_168_111_435_194_686_092 => "bad"
      }
    }
  end
end
