-- Run against DB_NAME before using the favorites and movie-records APIs.
CREATE TABLE IF NOT EXISTS favorite (
  favorite_id INT NOT NULL AUTO_INCREMENT,
  member_id INT NOT NULL,
  movie_id INT NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (favorite_id),
  CONSTRAINT uk_favorite_member_movie UNIQUE (member_id, movie_id),
  CONSTRAINT fk_favorite_member FOREIGN KEY (member_id) REFERENCES member (member_id)
) ENGINE=InnoDB;
