FROM gitlab/gitlab-runner:alpine
VOLUME ["/home/gitlab-runner/"]
ADD start.sh /
RUN chmod +x /start.sh
ENTRYPOINT ["/usr/bin/dumb-init", "/start.sh"]
CMD ["run", "--user=gitlab-runner", "--working-directory=/home/gitlab-runner"]
