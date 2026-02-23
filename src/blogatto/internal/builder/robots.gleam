//// Robots.txt builder module. Generates a robots.txt file based on the configuration.

import blogatto/config
import blogatto/config/robots
import blogatto/error
import blogatto/internal/path
import gleam/list
import gleam/result
import simplifile
import webls/robots as webls_robots

/// Build the robots.txt file based on the provided configuration.
pub fn build(
  out_directory: String,
  config: robots.RobotsConfig,
) -> Result(Nil, error.BlogattoError) {
  let robots_txt = path.join(out_directory, "robots.txt")
  let robots_config =
    list.map(config.robots, fn(robot) {
      robot.user_agent
      |> webls_robots.robot()
      |> webls_robots.with_robot_allowed_routes(robot.allowed_routes)
      |> webls_robots.with_robot_disallowed_routes(robot.disallowed_routes)
    })

  let robots_content =
    config.sitemap_url
    |> webls_robots.config()
    |> webls_robots.with_config_robots(robots_config)
    |> webls_robots.to_string()

  robots_txt
  |> simplifile.write(robots_content)
  |> result.map_error(error.File)
}
